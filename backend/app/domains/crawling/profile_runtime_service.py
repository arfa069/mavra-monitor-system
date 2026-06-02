from __future__ import annotations

import asyncio
import io
import os
import platform
import shutil
import tarfile
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path

from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.crawler_paths import build_profile_dir
from app.core.system_log import emit_system_log_detached
from app.domains.crawling import profile_service
from app.domains.crawling.profile_pool import AVAILABLE, DISABLED, LOGIN_REQUIRED
from app.models.crawl_profile import CrawlProfile

_BACKUP_MAGIC = b"PM_PROFILE_BACKUP_V1\n"
_SALT_SIZE = 16


@dataclass
class LoginSession:
    profile_key: str
    platform: str
    start_url: str
    context: object
    page: object
    executor: ThreadPoolExecutor
    started_at: float


_sessions: dict[str, LoginSession] = {}
_profile_locks: dict[str, asyncio.Lock] = {}


class ProfileAlreadyOpenError(RuntimeError):
    pass


class ProfileRuntimeUnsupportedError(RuntimeError):
    pass


class ProfileBackupError(RuntimeError):
    pass


def _profile_lock(profile_key: str) -> asyncio.Lock:
    lock = _profile_locks.get(profile_key)
    if lock is None:
        lock = asyncio.Lock()
        _profile_locks[profile_key] = lock
    return lock


def _new_profile_runtime_executor(profile_key: str) -> ThreadPoolExecutor:
    return ThreadPoolExecutor(max_workers=1, thread_name_prefix=f"profile-runtime-{profile_key}")


async def _run_on_profile_executor(executor: ThreadPoolExecutor, func):
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(executor, func)


def is_login_session_open(profile_key: str) -> bool:
    return profile_key in _sessions


def default_start_url(platform_name: str) -> str:
    return {
        "boss": "https://www.zhipin.com/",
        "51job": "https://www.51job.com/",
        "liepin": "https://www.liepin.com/",
        "jd": "https://www.jd.com/",
        "taobao": "https://www.taobao.com/",
        "amazon": "https://www.amazon.com/",
    }.get(platform_name, "https://www.zhipin.com/")


def runtime_capabilities() -> dict:
    os_name = platform.system().lower() or "unknown"
    has_gui = os_name == "windows" or bool(os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"))
    return {
        "os": os_name,
        "mode": "local_gui" if has_gui else "headless_server",
        "supports_login_session": has_gui,
        "supports_profile_import": True,
        "supports_profile_export": has_gui,
        "recommended_action": "open_login_browser" if has_gui else "import_profile_backup",
    }


def _assert_not_leased(profile: CrawlProfile) -> None:
    if profile.lease_until is not None and profile.lease_until > datetime.now(UTC):
        raise profile_service.CrawlProfileLeaseActiveError(profile.profile_key)


def _derive_key(password: str, salt: bytes) -> bytes:
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=390000,
    )
    import base64

    return base64.urlsafe_b64encode(kdf.derive(password.encode("utf-8")))


def _encrypt(data: bytes, password: str) -> bytes:
    salt = os.urandom(_SALT_SIZE)
    token = Fernet(_derive_key(password, salt)).encrypt(data)
    return _BACKUP_MAGIC + salt + token


def _decrypt(data: bytes, password: str) -> bytes:
    if not data.startswith(_BACKUP_MAGIC):
        raise ProfileBackupError("Invalid profile backup format")
    salt_start = len(_BACKUP_MAGIC)
    salt = data[salt_start : salt_start + _SALT_SIZE]
    token = data[salt_start + _SALT_SIZE :]
    try:
        return Fernet(_derive_key(password, salt)).decrypt(token)
    except InvalidToken as exc:
        raise ProfileBackupError("Invalid profile backup password") from exc


def _make_tar_bytes(profile_dir: Path) -> bytes:
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w:gz") as archive:
        if profile_dir.exists():
            for path in profile_dir.rglob("*"):
                archive.add(path, arcname=path.relative_to(profile_dir))
    return buffer.getvalue()


def _safe_extract_tar(data: bytes, target_dir: Path) -> None:
    target_dir.mkdir(parents=True, exist_ok=True)
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
        for member in archive.getmembers():
            member_path = Path(member.name)
            if member_path.is_absolute() or ".." in member_path.parts:
                raise ProfileBackupError("Profile backup contains unsafe paths")
        with tempfile.TemporaryDirectory() as tmp:
            tmp_dir = Path(tmp)
            archive.extractall(tmp_dir)
            for item in tmp_dir.rglob("*"):
                if item.is_file():
                    dest = target_dir / item.relative_to(tmp_dir)
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_bytes(item.read_bytes())


def _clear_profile_dir(profile_dir: Path) -> None:
    if not profile_dir.exists():
        return
    for item in profile_dir.iterdir():
        if item.is_dir() and not item.is_symlink():
            shutil.rmtree(item)
        else:
            item.unlink()


async def open_login_session(
    db: AsyncSession,
    *,
    profile_key: str,
    platform_name: str,
    start_url: str | None,
) -> dict:
    async with _profile_lock(profile_key):
        caps = runtime_capabilities()
        if not caps["supports_login_session"]:
            raise ProfileRuntimeUnsupportedError("Current server does not support visible browser sessions")
        profile = await profile_service.get_profile(db, profile_key)
        _assert_not_leased(profile)
        if profile_key in _sessions:
            raise ProfileAlreadyOpenError(profile_key)

        url = start_url or default_start_url(platform_name)

        def _open():
            from cloakbrowser import launch_persistent_context

            context = launch_persistent_context(
                str(build_profile_dir(profile_key)),
                headless=False,
                locale="zh-CN",
                timezone="Asia/Shanghai",
                humanize=True,
                viewport={"width": 1440, "height": 1000},
            )
            page = context.new_page()
            page.goto(url, wait_until="domcontentloaded", timeout=60000)
            return context, page

        executor = _new_profile_runtime_executor(profile_key)
        try:
            context, page = await _run_on_profile_executor(executor, _open)
        except Exception as exc:
            executor.shutdown(wait=False, cancel_futures=True)
            await emit_system_log_detached(
                category="runtime",
                event_type="profile_login.session_failed",
                source="crawler",
                severity="error",
                status="failed",
                message=f"Profile login session failed for {profile_key}",
                entity_type="crawl_profile",
                entity_id=profile_key,
                payload={"profile_key": profile_key, "platform": platform_name, "reason": str(exc)},
            )
            raise

        _sessions[profile_key] = LoginSession(
            profile_key=profile_key,
            platform=platform_name,
            start_url=url,
            context=context,
            page=page,
            executor=executor,
            started_at=time.time(),
        )
        await emit_system_log_detached(
            category="runtime",
            event_type="profile_login.session_started",
            source="crawler",
            severity="info",
            status="running",
            message=f"Profile login session started for {profile_key}",
            entity_type="crawl_profile",
            entity_id=profile_key,
            payload={"profile_key": profile_key, "platform": platform_name},
        )
        return {"profile_key": profile_key, "platform": platform_name, "status": "active", "start_url": url}


async def get_login_session(profile_key: str) -> dict:
    session = _sessions.get(profile_key)
    if session is None:
        return {
            "profile_key": profile_key,
            "platform": "",
            "status": "closed",
            "start_url": "",
            "message": "No active login session",
        }
    return {
        "profile_key": profile_key,
        "platform": session.platform,
        "status": "active",
        "start_url": session.start_url,
    }


async def close_login_session(profile_key: str) -> dict:
    async with _profile_lock(profile_key):
        session = _sessions.pop(profile_key, None)
        if session is None:
            return {
                "profile_key": profile_key,
                "platform": "",
                "status": "closed",
                "start_url": "",
                "message": "No active login session",
            }

        try:
            await _run_on_profile_executor(session.executor, session.context.close)
        finally:
            session.executor.shutdown(wait=False, cancel_futures=True)
        await emit_system_log_detached(
            category="runtime",
            event_type="profile_login.session_closed",
            source="crawler",
            severity="info",
            status="closed",
            message=f"Profile login session closed for {profile_key}",
            entity_type="crawl_profile",
            entity_id=profile_key,
            payload={"profile_key": profile_key, "platform": session.platform},
        )
        return {
            "profile_key": profile_key,
            "platform": session.platform,
            "status": "closed",
            "start_url": session.start_url,
        }


async def export_profile_backup(db: AsyncSession, *, profile_key: str, password: str) -> bytes:
    async with _profile_lock(profile_key):
        profile = await profile_service.get_profile(db, profile_key)
        _assert_not_leased(profile)
        if profile_key in _sessions:
            raise ProfileAlreadyOpenError(profile_key)
        profile_dir = build_profile_dir(profile_key)
        data = await asyncio.to_thread(_make_tar_bytes, profile_dir)
        encrypted = await asyncio.to_thread(_encrypt, data, password)
        await emit_system_log_detached(
            category="runtime",
            event_type="profile_backup.exported",
            source="crawler",
            severity="info",
            status="success",
            message=f"Profile backup exported for {profile_key}",
            entity_type="crawl_profile",
            entity_id=profile_key,
            payload={"profile_key": profile_key},
        )
        return encrypted


async def import_profile_backup(
    db: AsyncSession,
    *,
    profile_key: str,
    password: str,
    data: bytes,
    force: bool,
) -> CrawlProfile:
    async with _profile_lock(profile_key):
        profile = await profile_service.get_profile(db, profile_key)
        _assert_not_leased(profile)
        if profile_key in _sessions:
            raise ProfileAlreadyOpenError(profile_key)
        profile_dir = build_profile_dir(profile_key)
        has_existing_files = profile_dir.exists() and any(profile_dir.iterdir())
        if has_existing_files and not force:
            raise ProfileBackupError("Profile directory already exists; set force=true to overwrite")

        decrypted = await asyncio.to_thread(_decrypt, data, password)
        if has_existing_files and force:
            await asyncio.to_thread(_clear_profile_dir, profile_dir)
        await asyncio.to_thread(_safe_extract_tar, decrypted, profile_dir)
        profile.status = AVAILABLE
        profile.last_error = None
        profile.updated_at = datetime.now(UTC)
        await db.commit()
        await db.refresh(profile)
        await emit_system_log_detached(
            category="runtime",
            event_type="profile_backup.imported",
            source="crawler",
            severity="info",
            status="success",
            message=f"Profile backup imported for {profile_key}",
            entity_type="crawl_profile",
            entity_id=profile_key,
            payload={"profile_key": profile_key},
        )
        return profile


async def test_profile(
    db: AsyncSession,
    *,
    profile_key: str,
    platform_name: str,
    start_url: str | None,
) -> dict:
    async with _profile_lock(profile_key):
        profile = await profile_service.get_profile(db, profile_key)
        _assert_not_leased(profile)
        if profile_key in _sessions:
            raise ProfileAlreadyOpenError(profile_key)
        url = start_url or default_start_url(platform_name)

        def _run_test() -> tuple[str, str | None]:
            from cloakbrowser import launch_persistent_context

            context = launch_persistent_context(
                str(build_profile_dir(profile_key)),
                headless=True,
                locale="zh-CN",
                timezone="Asia/Shanghai",
                humanize=True,
                viewport={"width": 1440, "height": 1000},
            )
            try:
                page = context.new_page()
                page.goto(url, wait_until="domcontentloaded", timeout=60000)
                text = page.content()
                current_url = page.url
            finally:
                context.close()
            marker = f"{current_url}\n{text}".lower()
            if "code=36" in marker or "code=37" in marker or "异常行为" in marker or "环境存在异常" in marker:
                return "risk_blocked", "Platform reported risk control"
            if "登录" in text and ("验证码" in text or "扫码" in text or "login" in marker):
                return "login_required", "Login or verification is required"
            return "ready", None

        await emit_system_log_detached(
            category="runtime",
            event_type="profile_login.test_started",
            source="crawler",
            severity="info",
            status="running",
            message=f"Profile test started for {profile_key}",
            entity_type="crawl_profile",
            entity_id=profile_key,
            payload={"profile_key": profile_key, "platform": platform_name},
        )
        try:
            executor = _new_profile_runtime_executor(f"{profile_key}-test")
            try:
                status, message = await _run_on_profile_executor(executor, _run_test)
            finally:
                executor.shutdown(wait=False, cancel_futures=True)
        except Exception as exc:
            status, message = "error", str(exc)

        profile.status = AVAILABLE if status == "ready" else LOGIN_REQUIRED if status == "login_required" else DISABLED
        profile.last_error = message
        profile.last_used_at = datetime.now(UTC)
        profile.updated_at = datetime.now(UTC)
        await db.commit()
        await db.refresh(profile)
        await emit_system_log_detached(
            category="runtime",
            event_type="profile_login.test_completed" if status == "ready" else "profile_login.test_failed",
            source="crawler",
            severity="info" if status == "ready" else "warning",
            status=status,
            message=f"Profile test {status} for {profile_key}",
            entity_type="crawl_profile",
            entity_id=profile_key,
            payload={"profile_key": profile_key, "platform": platform_name},
        )
        return {"profile_key": profile_key, "platform": platform_name, "status": status, "message": message}
