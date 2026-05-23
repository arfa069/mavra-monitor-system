"""Job domain business services."""

from sqlalchemy.ext.asyncio import AsyncSession

from app.domains.jobs import repository
from app.models.job import JobSearchConfig
from app.models.user import User
from app.schemas.job import (
    JobConfigCronUpdate,
    JobSearchConfigCreate,
    JobSearchConfigUpdate,
)
from app.schemas.job_match import UserResumeCreate, UserResumeUpdate

DEFAULT_CRON_TIMEZONE = "Asia/Shanghai"
CRON_FIELDS = {"cron_expression", "cron_timezone"}


class JobConfigNotFoundError(LookupError):
    """Raised when a job config cannot be found for the current user."""


class JobConfigCronPermissionError(PermissionError):
    """Raised when a non-super-admin attempts to modify cron fields."""


class UserResumeNotFoundError(LookupError):
    """Raised when a resume cannot be found for the current user."""


class JobNotFoundError(LookupError):
    """Raised when a job cannot be found for the current user."""


async def list_job_configs(
    db: AsyncSession, *, user_id: int, active: bool | None
) -> list[JobSearchConfig]:
    return await repository.list_job_configs(db, user_id=user_id, active=active)


async def create_job_config(
    db: AsyncSession, *, user_id: int, data: JobSearchConfigCreate
) -> JobSearchConfig:
    return await repository.create_job_config(
        db, user_id=user_id, data=data.model_dump()
    )


async def get_job_config(
    db: AsyncSession, *, user_id: int, config_id: int
) -> JobSearchConfig:
    config = await repository.get_job_config(db, user_id=user_id, config_id=config_id)
    if not config:
        raise JobConfigNotFoundError
    return config


async def update_job_config(
    db: AsyncSession,
    *,
    actor: User,
    config_id: int,
    data: JobSearchConfigUpdate,
) -> tuple[JobSearchConfig, dict]:
    config = await get_job_config(db, user_id=actor.id, config_id=config_id)
    update_data = data.model_dump(exclude_unset=True)

    if CRON_FIELDS & set(update_data) and actor.role != "super_admin":
        raise JobConfigCronPermissionError

    config = await repository.update_job_config(db, config=config, data=update_data)
    return config, update_data


async def delete_job_config(
    db: AsyncSession, *, user_id: int, config_id: int
) -> tuple[JobSearchConfig, dict]:
    config = await get_job_config(db, user_id=user_id, config_id=config_id)
    config_info = {"name": config.name}
    await repository.delete_job_config(db, config=config)
    return config, config_info


async def remove_job_config(db: AsyncSession, *, config: JobSearchConfig) -> None:
    await repository.delete_job_config(db, config=config)


async def update_job_config_cron(
    db: AsyncSession,
    *,
    user_id: int,
    config_id: int,
    data: JobConfigCronUpdate,
) -> JobSearchConfig:
    config = await get_job_config(db, user_id=user_id, config_id=config_id)
    config = await repository.update_job_config(
        db,
        config=config,
        data={
            "cron_expression": data.cron_expression,
            "cron_timezone": data.cron_timezone or DEFAULT_CRON_TIMEZONE,
        },
    )
    return config


async def list_job_config_ids(db: AsyncSession, *, user_id: int) -> set[int]:
    return await repository.list_job_config_ids(db, user_id=user_id)


async def list_user_resumes(db: AsyncSession, *, user_id: int):
    return await repository.list_user_resumes(db, user_id=user_id)


async def create_user_resume(
    db: AsyncSession, *, user_id: int, data: UserResumeCreate
):
    return await repository.create_user_resume(
        db, user_id=user_id, data=data.model_dump()
    )


async def get_user_resume(db: AsyncSession, *, user_id: int, resume_id: int):
    resume = await repository.get_user_resume(
        db, user_id=user_id, resume_id=resume_id
    )
    if not resume:
        raise UserResumeNotFoundError
    return resume


async def validate_resume_owner(
    db: AsyncSession, *, user_id: int, resume_id: int
):
    resume = await repository.get_user_resume_by_id(db, resume_id=resume_id)
    if not resume or resume.user_id != user_id:
        raise UserResumeNotFoundError
    return resume


async def update_user_resume(
    db: AsyncSession, *, user_id: int, resume_id: int, data: UserResumeUpdate
):
    resume = await get_user_resume(db, user_id=user_id, resume_id=resume_id)
    return await repository.update_user_resume(
        db, resume=resume, data=data.model_dump(exclude_unset=True)
    )


async def delete_user_resume(db: AsyncSession, *, user_id: int, resume_id: int) -> None:
    resume = await get_user_resume(db, user_id=user_id, resume_id=resume_id)
    await repository.delete_user_resume(db, resume=resume)


async def list_match_results(
    db: AsyncSession,
    *,
    user_id: int,
    resume_id: int | None,
    job_id: int | None,
    min_score: int | None,
    page: int,
    page_size: int,
):
    return await repository.list_match_results(
        db,
        user_id=user_id,
        resume_id=resume_id,
        job_id=job_id,
        min_score=min_score,
        page=page,
        page_size=page_size,
    )


async def list_user_job_ids(db: AsyncSession, *, user_id: int) -> list[int]:
    return await repository.list_user_job_ids(db, user_id=user_id)


async def list_job_crawl_logs(
    db: AsyncSession,
    *,
    user_id: int,
    search_config_id: int | None,
    status: str | None,
    hours: int,
    limit: int,
):
    config_ids = await list_job_config_ids(db, user_id=user_id)
    if not config_ids:
        return []
    return await repository.list_job_crawl_logs(
        db,
        config_ids=config_ids,
        search_config_id=search_config_id,
        status=status,
        hours=hours,
        limit=limit,
    )


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
):
    return await repository.list_jobs(
        db,
        user_id=user_id,
        search_config_id=search_config_id,
        keyword=keyword,
        company=company,
        salary_min=salary_min,
        salary_max=salary_max,
        location=location,
        is_active=is_active,
        sort_by=sort_by,
        sort_order=sort_order,
        page=page,
        page_size=page_size,
    )


async def get_job(db: AsyncSession, *, user_id: int, job_id: str):
    job = await repository.get_job_by_job_id(db, user_id=user_id, job_id=job_id)
    if not job:
        raise JobNotFoundError
    return job
