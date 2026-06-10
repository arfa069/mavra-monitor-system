"""Job domain data access helpers."""

from datetime import UTC, datetime, timedelta
from inspect import isawaitable

from sqlalchemy import asc, case, desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.job import Job, JobSearchConfig
from app.models.job_crawl_log import JobCrawlLog
from app.models.job_match import MatchResult, UserResume


def _recommendation_rank_case():
    """Build a SQLAlchemy case expression that maps apply_recommendation to a numeric rank."""
    return case(
        (MatchResult.apply_recommendation == "强烈推荐", 3),
        (MatchResult.apply_recommendation == "可以考虑", 2),
        (MatchResult.apply_recommendation == "不太匹配", 1),
        else_=0,
    )


async def list_job_configs(
    db: AsyncSession, *, user_id: int, active: bool | None
) -> list[JobSearchConfig]:
    query = select(JobSearchConfig).where(JobSearchConfig.user_id == user_id)
    if active is not None:
        query = query.where(JobSearchConfig.active == active)
    result = await db.execute(query.order_by(desc(JobSearchConfig.created_at)))
    return list(result.scalars().all())


async def get_job_config(
    db: AsyncSession, *, user_id: int, config_id: int
) -> JobSearchConfig | None:
    result = await db.execute(
        select(JobSearchConfig).where(
            JobSearchConfig.id == config_id,
            JobSearchConfig.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def create_job_config(
    db: AsyncSession, *, user_id: int, data: dict
) -> JobSearchConfig:
    config = JobSearchConfig(user_id=user_id, **data)
    added = db.add(config)
    if isawaitable(added):
        await added
    await db.commit()
    await db.refresh(config)
    return config


async def update_job_config(
    db: AsyncSession, *, config: JobSearchConfig, data: dict
) -> JobSearchConfig:
    for field, value in data.items():
        setattr(config, field, value)
    await db.commit()
    await db.refresh(config)
    return config


async def delete_job_config(db: AsyncSession, *, config: JobSearchConfig) -> None:
    await db.delete(config)
    await db.commit()


async def list_job_config_ids(db: AsyncSession, *, user_id: int) -> set[int]:
    result = await db.execute(
        select(JobSearchConfig.id).where(JobSearchConfig.user_id == user_id)
    )
    return set(result.scalars().all())


async def list_user_resumes(db: AsyncSession, *, user_id: int) -> list[UserResume]:
    result = await db.execute(
        select(UserResume)
        .where(UserResume.user_id == user_id)
        .order_by(desc(UserResume.created_at))
    )
    return list(result.scalars().all())


async def create_user_resume(
    db: AsyncSession, *, user_id: int, data: dict
) -> UserResume:
    resume = UserResume(user_id=user_id, **data)
    added = db.add(resume)
    if isawaitable(added):
        await added
    await db.commit()
    await db.refresh(resume)
    return resume


async def get_user_resume(
    db: AsyncSession, *, user_id: int, resume_id: int
) -> UserResume | None:
    result = await db.execute(
        select(UserResume).where(
            UserResume.id == resume_id,
            UserResume.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def get_user_resume_by_id(db: AsyncSession, *, resume_id: int) -> UserResume | None:
    return await db.get(UserResume, resume_id)


async def update_user_resume(
    db: AsyncSession, *, resume: UserResume, data: dict
) -> UserResume:
    for field, value in data.items():
        setattr(resume, field, value)
    await db.commit()
    await db.refresh(resume)
    return resume


async def delete_user_resume(db: AsyncSession, *, resume: UserResume) -> None:
    await db.delete(resume)
    await db.commit()


async def list_match_results(
    db: AsyncSession,
    *,
    user_id: int,
    resume_id: int | None,
    job_id: int | None,
    min_score: int | None,
    recommendation: str | None,
    page: int,
    page_size: int,
) -> tuple[list[MatchResult], int]:
    recommendation_rank = _recommendation_rank_case()
    query = (
        select(MatchResult)
        .join(UserResume, MatchResult.resume_id == UserResume.id)
        .join(Job, MatchResult.job_id == Job.id)
        .options(selectinload(MatchResult.job))
        .where(UserResume.user_id == user_id)
        .order_by(desc(recommendation_rank), desc(MatchResult.updated_at))
    )
    count_query = (
        select(func.count())
        .select_from(MatchResult)
        .join(UserResume, MatchResult.resume_id == UserResume.id)
        .where(UserResume.user_id == user_id)
    )

    if resume_id is not None:
        query = query.where(MatchResult.resume_id == resume_id)
        count_query = count_query.where(MatchResult.resume_id == resume_id)
    if job_id is not None:
        query = query.where(MatchResult.job_id == job_id)
        count_query = count_query.where(MatchResult.job_id == job_id)
    if min_score is not None:
        query = query.where(MatchResult.match_score >= min_score)
        count_query = count_query.where(MatchResult.match_score >= min_score)
    if recommendation:
        query = query.where(MatchResult.apply_recommendation == recommendation)
        count_query = count_query.where(MatchResult.apply_recommendation == recommendation)

    total = (await db.execute(count_query)).scalar() or 0
    result = await db.execute(query.offset((page - 1) * page_size).limit(page_size))
    return list(result.scalars().all()), total


async def list_user_job_ids(db: AsyncSession, *, user_id: int) -> list[int]:
    result = await db.execute(
        select(Job.id).join(JobSearchConfig).where(JobSearchConfig.user_id == user_id)
    )
    return list(result.scalars().all())


async def list_job_crawl_logs(
    db: AsyncSession,
    *,
    config_ids: set[int],
    search_config_id: int | None,
    status: str | None,
    hours: int,
    limit: int,
) -> list[JobCrawlLog]:
    query = select(JobCrawlLog).where(JobCrawlLog.search_config_id.in_(config_ids))

    if search_config_id is not None:
        query = query.where(JobCrawlLog.search_config_id == search_config_id)
    if status is not None:
        query = query.where(JobCrawlLog.status == status)

    cutoff = datetime.now(UTC) - timedelta(hours=hours)
    query = (
        query.where(JobCrawlLog.scraped_at >= cutoff)
        .order_by(JobCrawlLog.scraped_at.desc())
        .limit(limit)
    )
    result = await db.execute(query)
    return list(result.scalars().all())


async def list_jobs(
    db: AsyncSession,
    *,
    user_id: int,
    search_config_id: int | None,
    keyword: str | None,
    company: str | None,
    salary_min: int | None,
    salary_max: int | None,
    location: str | None,
    is_active: bool | None,
    sort_by: str,
    sort_order: str,
    page: int,
    page_size: int,
) -> tuple[list[Job], int, dict[int, str | None]]:
    query = (
        select(Job)
        .join(JobSearchConfig)
        .options(selectinload(Job.search_config))
        .where(JobSearchConfig.user_id == user_id)
    )
    count_query = (
        select(func.count())
        .select_from(Job)
        .join(JobSearchConfig)
        .where(JobSearchConfig.user_id == user_id)
    )

    if search_config_id is not None:
        query = query.where(Job.search_config_id == search_config_id)
        count_query = count_query.where(Job.search_config_id == search_config_id)
    if keyword:
        keyword_filter = (
            Job.title.ilike(f"%{keyword}%")
            | Job.company.ilike(f"%{keyword}%")
            | Job.description.ilike(f"%{keyword}%")
        )
        query = query.where(keyword_filter)
        count_query = count_query.where(keyword_filter)
    if company:
        query = query.where(Job.company.ilike(f"%{company}%"))
        count_query = count_query.where(Job.company.ilike(f"%{company}%"))
    if salary_min is not None:
        query = query.where(Job.salary_min >= salary_min)
        count_query = count_query.where(Job.salary_min >= salary_min)
    if salary_max is not None:
        query = query.where(Job.salary_max <= salary_max)
        count_query = count_query.where(Job.salary_max <= salary_max)
    if location:
        query = query.where(Job.location.ilike(f"%{location}%"))
        count_query = count_query.where(Job.location.ilike(f"%{location}%"))
    if is_active is not None:
        query = query.where(Job.is_active == is_active)
        count_query = count_query.where(Job.is_active == is_active)

    sort_column = {
        "first_seen_at": Job.first_seen_at,
        "last_updated_at": Job.last_updated_at,
        "salary_min": Job.salary_min,
    }.get(sort_by, Job.first_seen_at)
    query = query.order_by(asc(sort_column) if sort_order == "asc" else desc(sort_column))

    total = (await db.execute(count_query)).scalar() or 0
    result = await db.execute(query.offset((page - 1) * page_size).limit(page_size))
    jobs = list(result.scalars().all())

    # 查这些 job 的最佳 match recommendation
    rec_map: dict[int, str | None] = {}
    if jobs:
        job_ids = [j.id for j in jobs]
        rank = _recommendation_rank_case()
        match_rows = await db.execute(
            select(MatchResult.job_id, MatchResult.apply_recommendation)
            .where(
                MatchResult.job_id.in_(job_ids),
                MatchResult.user_id == user_id,
            )
            .order_by(MatchResult.job_id, rank.desc())
            .distinct(MatchResult.job_id)
        )
        rec_map = {row.job_id: row.apply_recommendation for row in match_rows}

    return jobs, total, rec_map


async def get_job_by_job_id(
    db: AsyncSession, *, user_id: int, job_id: str
) -> Job | None:
    result = await db.execute(
        select(Job)
        .join(JobSearchConfig)
        .options(selectinload(Job.search_config))
        .where(
            Job.job_id == job_id,
            JobSearchConfig.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()
