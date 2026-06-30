"""Application configuration using Pydantic Settings."""
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_env_file = next(
    (p for p in (
        Path(__file__).parent.parent.parent / ".env",
        Path(__file__).parent.parent / ".env",
    ) if p.exists()),
    None,
)


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    model_config = SettingsConfigDict(env_file=_env_file, extra="ignore")

    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/pricemonitor"

    # Redis - supports password in URL format: redis://:password@host:port/0
    # or use separate redis_password field below
    redis_url: str = "redis://localhost:6379/0"
    redis_password: str = ""  # Alternative: specify password separately

    # Feishu (fallback/default webhook)
    feishu_webhook_url: str = ""

    # Crawler settings
    crawl_frequency_hours: int = 1
    data_retention_days: int = 365

    # Proxy settings (optional, for rotating IPs to avoid anti-bot detection)
    crawl_proxy_url: str = ""  # e.g. "http://user:pass@host:port" or "socks5://host:port"
    crawl_proxy_enabled: bool = False

    # Taobao-specific options
    taobao_js_deep_scan_enabled: bool = False

    # Platform cookies (optional, for bypassing login walls)
    jd_cookie: str = ""  # Cookie string for JD login session
    jd_cookie_fallback_enabled: bool = False
    product_cdp_fallback_enabled: bool = False

    # CDP (Chrome DevTools Protocol) browser connection
    # When enabled, connects to an existing browser via CDP instead of launching a new one.
    # This allows using a real browser session (with cookies/login already set).
    # Usage: start Edge/Chrome with --remote-debugging-port=9222, login to JD, then enable this.
    cdp_enabled: bool = False
    cdp_url: str = "http://127.0.0.1:9222"  # CDP endpoint for existing browser
    cdp_allow_non_local: bool = False

    # JWT settings
    jwt_secret_key: str = "your-secret-key-change-in-production"

    # Smart home settings
    smart_home_secret_key: str = ""

    # Blog settings
    blog_media_root: str = "uploads/blog"
    blog_media_public_prefix: str = "/blog-media"
    blog_media_max_bytes: int = Field(default=8 * 1024 * 1024, ge=1)
    blog_public_base_url: str = "http://localhost:3001"

    # App settings
    app_name: str = "Price Monitor"
    debug: bool = False
    database_echo: bool = False
    allowed_origins: list[str] = ["http://localhost:3000", "http://127.0.0.1:3000"]
    crawler_headless: bool = True
    product_crawl_concurrency: int = Field(default=1, ge=1)
    product_crawl_engine: str = "opencli"
    firecrawl_api_url: str = "https://api.firecrawl.dev"
    firecrawl_api_key: str = ""
    firecrawl_timeout_seconds: float = 60.0
    firecrawl_wait_for_ms: int = 2000
    firecrawl_profile_name: str = ""

    # Auth cookie settings
    auth_access_cookie_name: str = "pm_access_token"
    auth_refresh_cookie_name: str = "pm_refresh_token"
    auth_csrf_cookie_name: str = "pm_csrf_token"
    auth_csrf_header_name: str = "X-CSRF-Token"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 14
    session_idle_timeout_minutes: int = 60
    auth_cookie_samesite: str = "lax"

    @property
    def auth_cookie_secure(self) -> bool:
        """Whether auth cookies should have the Secure flag."""
        return not self.debug

    # WeChat login settings
    wechat_login_enabled: bool = False
    wechat_app_id: str | None = None
    wechat_app_secret: str | None = None
    wechat_redirect_uri: str | None = None
    wechat_frontend_callback_url: str | None = None
    wechat_flutter_web_callback_url: str | None = None
    wechat_android_callback_url: str = "mavra://auth/wechat/callback"
    wechat_ios_callback_url: str = "mavra://auth/wechat/callback"
    wechat_windows_callback_url: str = "mavra://auth/wechat/callback"

    # Crawler worker settings
    crawler_worker_poll_interval_seconds: float = 5.0
    crawler_worker_heartbeat_interval_seconds: float = 15.0
    crawler_worker_maintenance_interval_seconds: float = 60.0
    crawler_worker_stale_after_seconds: int = 120
    crawler_task_lease_seconds: int = 3600
    crawler_task_max_requeue_attempts: int = 5
    crawler_profile_busy_retry_delay_seconds: float = 30.0
    crawler_worker_concurrency: int = 1

    # JD OpenCLI integration
    jd_opencli_command: str = "opencli"
    jd_opencli_timeout_seconds: float = 60.0

    # Taobao OpenCLI integration
    taobao_opencli_command: str = "opencli"
    taobao_opencli_timeout_seconds: float = 60.0

    # LLM job match settings
    job_match_provider: str = "minimax"
    job_match_model: str = "MiniMax-M2.7"
    minimax_api_key: str = ""
    minimax_base_url: str = "https://api.minimaxi.com/anthropic"
    # Backward-compatible aliases for older configs.
    anthropic_api_key: str = ""
    anthropic_base_url: str = ""
    openai_api_key: str = ""
    ollama_base_url: str = "http://127.0.0.1:11434"

    @field_validator("allowed_origins", mode="before")
    @classmethod
    def parse_allowed_origins(cls, value):
        if isinstance(value, str):
            stripped = value.strip()
            if stripped.startswith("[") and stripped.endswith("]"):
                import json
                try:
                    return json.loads(stripped)
                except Exception:
                    pass
            return [item.strip() for item in stripped.split(",") if item.strip()]
        return value

    @field_validator("debug", mode="before")
    @classmethod
    def parse_debug(cls, value):
        if isinstance(value, str):
            normalized = value.strip().lower()
            if normalized in {"release", "prod", "production"}:
                return False
            if normalized in {"debug", "dev", "development"}:
                return True
        return value

    @field_validator("jwt_secret_key")
    @classmethod
    def _check_jwt_secret(cls, v: str) -> str:
        if v in ("your-secret-key-change-in-production", "change-this-to-a-random-secret-key", ""):
            raise ValueError(
                "JWT_SECRET_KEY 不能使用默认值。请设置一个随机强密钥，"
                "或在 .env 文件中配置 JWT_SECRET_KEY。"
            )
        return v

    @property
    def redis_url_with_password(self) -> str:
        """Build Redis URL with password if redis_password is set."""
        if self.redis_password:
            # Insert password into URL: redis://host:6379/0 -> redis://:password@host:6379/0
            from urllib.parse import urlparse
            parsed = urlparse(self.redis_url)
            return f"redis://:{self.redis_password}@{parsed.hostname}:{parsed.port or 6379}/{parsed.path.lstrip('/')}"
        return self.redis_url


settings = Settings()
