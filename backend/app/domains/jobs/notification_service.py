"""Job notification message builders."""
from __future__ import annotations

from app.core.user_config_cache import get_cached_user_config
from app.integrations.feishu import send_feishu_notification
from app.models.job import JobSearchConfig


async def send_new_job_notification(
    config: JobSearchConfig,
    new_job_count: int,
    total_scraped: int,
) -> dict:
    """Send Feishu notification for newly discovered jobs."""
    user = await get_cached_user_config()

    if not user or not user.get("feishu_webhook_url"):
        return {"status": "skipped", "reason": "no_webhook"}

    platform_names = {
        "boss": "Boss直聘",
        "51job": "前程无忧",
        "liepin": "猎聘",
    }
    platform_label = platform_names.get(
        getattr(config, "platform", "boss"), "招聘平台"
    )

    message = f"""🔔 {platform_label}新职位提醒

搜索配置：{config.name}
本次发现 {new_job_count} 个新职位（共扫描 {total_scraped} 个）

---
共收录职位请查看管理后台"""

    return await send_feishu_notification(user["feishu_webhook_url"], message)
