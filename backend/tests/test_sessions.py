"""Tests for session management (Task 3: refresh-token-aware helpers)."""
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.core.tokens import hash_token
from app.database import get_db
from app.main import app


@pytest.fixture
def mock_db_session():
    """Mock database session for session tests."""
    session = AsyncMock()
    session.execute = AsyncMock()
    session.commit = AsyncMock()
    session.add = MagicMock()
    session.refresh = AsyncMock()
    session.delete = AsyncMock()
    return session


@pytest.fixture
def mock_get_db(mock_db_session):
    """Override get_db dependency with mock session."""
    async def _override():
        yield mock_db_session
    app.dependency_overrides[get_db] = _override
    yield mock_db_session
    app.dependency_overrides.pop(get_db, None)


@pytest.fixture
def test_user():
    """Test user data for authentication tests."""
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpassword123",
    }


# ── Legacy create_session_with_token tests ──────────────────────────────────


@pytest.mark.asyncio
async def test_create_session_with_token(mock_db_session, test_user):
    """Test creating a new session with token (legacy, auto-commit)."""
    from app.core.security import create_session_with_token

    token = "test_token_123"
    device = "Chrome on Windows"
    ip_address = "192.168.1.1"

    # Mock: user has no existing sessions
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = []
    mock_db_session.execute.return_value = mock_result

    session = await create_session_with_token(
        user_id=1,
        token=token,
        device=device,
        ip_address=ip_address,
        db=mock_db_session,
    )

    assert session is not None
    mock_db_session.add.assert_called_once()
    mock_db_session.commit.assert_called_once()


@pytest.mark.asyncio
async def test_create_session_with_token_max_5_removes_oldest(mock_db_session):
    """Test that creating 6 sessions with token removes the oldest."""
    from app.core.security import create_session_with_token

    # Mock: user already has 5 sessions
    existing_sessions = [MagicMock(id=i + 1) for i in range(5)]
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = existing_sessions
    mock_db_session.execute.return_value = mock_result

    await create_session_with_token(
        user_id=1,
        token="token_6",
        device="New Device",
        ip_address="192.168.1.100",
        db=mock_db_session,
    )

    # Should delete the oldest (first) session
    assert mock_db_session.delete.call_count >= 1


# ── New create_session (refresh-token-based) tests ──────────────────────────


@pytest.mark.asyncio
async def test_new_create_session_stores_hash_not_raw_token(mock_db_session):
    """Verify new create_session stores hashed token, not raw refresh_token."""
    from app.core.sessions import create_session

    # No existing sessions
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = []
    mock_db_session.execute.return_value = mock_result

    raw_token = "my-super-secret-refresh-token"
    session = await create_session(
        user_id=1,
        refresh_token=raw_token,
        device="iPhone",
        ip_address="10.0.0.1",
        db=mock_db_session,
    )

    # Session object created
    assert session is not None
    # refresh_token_hash should be the SHA256 hash, not the raw token
    assert session.refresh_token_hash == hash_token(raw_token)
    assert session.refresh_token_hash != raw_token
    # refresh_expires_at should be set
    assert session.refresh_expires_at is not None
    # device and ip_address should be passed through
    assert session.device == "iPhone"
    assert session.ip_address == "10.0.0.1"
    # Should NOT auto-commit
    mock_db_session.commit.assert_not_called()
    # Should add to session
    mock_db_session.add.assert_called_once_with(session)


@pytest.mark.asyncio
async def test_new_create_session_no_auto_commit(mock_db_session):
    """Verify new create_session does NOT auto-commit."""
    from app.core.sessions import create_session

    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = []
    mock_db_session.execute.return_value = mock_result

    session = await create_session(
        user_id=1,
        refresh_token="some-token",
        device="Test",
        ip_address="127.0.0.1",
        db=mock_db_session,
    )

    assert session is not None
    mock_db_session.commit.assert_not_called()


@pytest.mark.asyncio
async def test_new_create_session_enforces_max_5(mock_db_session):
    """Verify new create_session enforces max 5 sessions per user."""
    from datetime import UTC, datetime, timedelta

    from app.core.sessions import create_session

    # User already has 5 sessions
    now = datetime.now(UTC)
    existing_sessions = [
        MagicMock(
            id=i + 1,
            user_id=1,
            refresh_token_hash=f"hash-{i}",
            created_at=now - timedelta(hours=6 - i),
        )
        for i in range(5)
    ]
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = existing_sessions
    mock_db_session.execute.return_value = mock_result

    session = await create_session(
        user_id=1,
        refresh_token="new-token",
        device="New Device",
        ip_address="10.0.0.99",
        db=mock_db_session,
    )

    assert session is not None
    # Should delete the oldest session (first in list, created_at oldest)
    mock_db_session.delete.assert_called_once_with(existing_sessions[0])
    mock_db_session.add.assert_called_once_with(session)
    mock_db_session.commit.assert_not_called()


# ── get_session_by_refresh_token tests ──────────────────────────────────────


@pytest.mark.asyncio
async def test_get_session_by_refresh_token_success(mock_db_session):
    """Verify get_session_by_refresh_token returns session for valid token."""
    from app.core.sessions import get_session_by_refresh_token

    raw_token = "valid-refresh-token"
    token_hash_val = hash_token(raw_token)

    mock_session = MagicMock()
    mock_session.refresh_token_hash = token_hash_val

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = mock_session
    mock_db_session.execute.return_value = mock_result

    result = await get_session_by_refresh_token(raw_token, mock_db_session)

    assert result is mock_session
    # Verify query used hashed token
    mock_db_session.execute.assert_called_once()
    statement = mock_db_session.execute.await_args.args[0]
    assert statement._for_update_arg is not None


@pytest.mark.asyncio
async def test_get_session_by_refresh_token_expired(mock_db_session):
    """Verify get_session_by_refresh_token returns None for expired token."""
    from app.core.sessions import get_session_by_refresh_token

    raw_token = "expired-refresh-token"

    # Mock: expired token — query returns None
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_db_session.execute.return_value = mock_result

    result = await get_session_by_refresh_token(raw_token, mock_db_session)

    assert result is None


@pytest.mark.asyncio
async def test_get_session_by_refresh_token_after_delete(mock_db_session):
    """Verify get_session_by_refresh_token returns None for deleted session."""
    from app.core.sessions import get_session_by_refresh_token

    raw_token = "deleted-refresh-token"

    # Mock: session was deleted — query returns None
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_db_session.execute.return_value = mock_result

    result = await get_session_by_refresh_token(raw_token, mock_db_session)

    assert result is None


# ── rotate_session_refresh_token tests ──────────────────────────────────────


@pytest.mark.asyncio
async def test_rotate_session_refresh_token(mock_db_session):
    """Verify rotate_session_refresh_token updates hash, expiry, and last_active."""
    from datetime import UTC

    from app.core.sessions import rotate_session_refresh_token

    old_hash = hash_token("old-refresh-token")
    new_raw = "new-refresh-token"

    mock_session = MagicMock()
    mock_session.refresh_token_hash = old_hash
    mock_session.refresh_expires_at = datetime.now(UTC) - timedelta(days=1)
    mock_session.last_active_at = datetime.now(UTC) - timedelta(hours=12)

    await rotate_session_refresh_token(mock_session, new_raw, mock_db_session)

    # Hash updated to new token's hash
    assert mock_session.refresh_token_hash == hash_token(new_raw)
    assert mock_session.refresh_token_hash != old_hash
    # Expiry updated to future
    assert mock_session.refresh_expires_at > datetime.now(UTC)
    # last_active_at updated
    assert mock_session.last_active_at > datetime.now(UTC) - timedelta(seconds=5)
    # No commit / delete / add called
    mock_db_session.commit.assert_not_called()
    mock_db_session.delete.assert_not_called()
    mock_db_session.add.assert_not_called()


# ── get_session_by_id tests ─────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_session_by_id_found(mock_db_session):
    """Verify get_session_by_id returns session when it exists for the user."""
    from app.core.sessions import get_session_by_id

    mock_session = MagicMock(id=42, user_id=1)

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = mock_session
    mock_db_session.execute.return_value = mock_result

    result = await get_session_by_id(42, 1, mock_db_session)

    assert result is mock_session
    mock_db_session.execute.assert_called_once()


@pytest.mark.asyncio
async def test_get_session_by_id_not_found(mock_db_session):
    """Verify get_session_by_id returns None for non-existent/wrong user."""
    from app.core.sessions import get_session_by_id

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_db_session.execute.return_value = mock_result

    result = await get_session_by_id(999, 2, mock_db_session)

    assert result is None


# ── Existing helper backward compat tests ───────────────────────────────────


@pytest.mark.asyncio
async def test_get_user_sessions(mock_db_session):
    """Test getting all sessions for a user."""
    from app.core.security import get_user_sessions

    # Mock: return 3 sessions
    mock_sessions = [MagicMock(id=i + 1, user_id=1) for i in range(3)]
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = mock_sessions
    mock_db_session.execute.return_value = mock_result

    sessions = await get_user_sessions(1, mock_db_session)

    assert len(sessions) == 3


@pytest.mark.asyncio
async def test_delete_session(mock_db_session):
    """Test deleting a specific session."""
    from app.core.security import delete_session

    # Mock: delete returns rowcount 1
    mock_result = MagicMock()
    mock_result.rowcount = 1
    mock_db_session.execute.return_value = mock_result

    deleted = await delete_session(1, 1, mock_db_session)

    assert deleted is True
    mock_db_session.commit.assert_called_once()


@pytest.mark.asyncio
async def test_delete_session_not_found(mock_db_session):
    """Test deleting a non-existent session."""
    from app.core.security import delete_session

    # Mock: delete returns rowcount 0
    mock_result = MagicMock()
    mock_result.rowcount = 0
    mock_db_session.execute.return_value = mock_result

    deleted = await delete_session(9999, 1, mock_db_session)

    assert deleted is False


@pytest.mark.asyncio
async def test_delete_other_sessions(mock_db_session):
    """Test deleting all sessions except the current one."""
    from app.core.security import delete_other_sessions

    # Mock: SELECT id returns 3 ids, then DELETE returns rowcount 3
    select_result = MagicMock()
    select_result.all.return_value = [(2,), (3,), (4,)]
    delete_result = MagicMock()
    delete_result.rowcount = 3
    mock_db_session.execute = AsyncMock(side_effect=[select_result, delete_result])

    count = await delete_other_sessions(1, 1, mock_db_session)

    assert count == 3
    mock_db_session.commit.assert_called_once()


@pytest.mark.asyncio
async def test_parse_device():
    """Test parsing device from user agent."""
    from app.core.security import parse_device

    assert parse_device("") == "Unknown"
    assert parse_device(None) == "Unknown"
    assert parse_device(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0"
    ) == "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0"
    # Test truncation
    long_ua = "A" * 300
    assert parse_device(long_ua) == "A" * 200


# ── API Endpoint Tests ──────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_session_response_model():
    """Test SessionResponse model can be instantiated."""
    from datetime import UTC, datetime

    from app.domains.auth.router import SessionResponse

    session_data = {
        "id": 1,
        "device": "Chrome on Windows",
        "ip_address": "192.168.1.1",
        "last_active_at": datetime.now(UTC),
        "created_at": datetime.now(UTC),
    }

    response = SessionResponse(**session_data)
    assert response.id == 1
    assert response.device == "Chrome on Windows"
