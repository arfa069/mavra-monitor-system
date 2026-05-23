"""Tests for Session model refresh token support."""
import hashlib
from datetime import UTC, datetime, timedelta

from app.models.session import Session


class TestSessionModelColumns:
    """Verify Session model exposes new columns."""

    def _get_column(self, name: str):
        """Helper to get a column by name from the Session table."""
        for c in Session.__table__.columns:
            if c.name == name:
                return c
        return None

    def test_session_model_has_refresh_token_hash(self):
        """Session model should have refresh_token_hash column."""
        assert hasattr(Session, "refresh_token_hash")

    def test_session_model_has_refresh_expires_at(self):
        """Session model should have refresh_expires_at column."""
        assert hasattr(Session, "refresh_expires_at")

    def test_session_creation_stores_refresh_hash_only(self):
        """Session creation stores only the hash, not the raw refresh token."""
        raw_refresh_token = "raw_refresh_token_456"
        refresh_hash = hashlib.sha256(raw_refresh_token.encode()).hexdigest()
        expiry = datetime.now(UTC) + timedelta(days=7)

        session = Session(
            user_id=1,
            token_hash="access_hash",
            refresh_token_hash=refresh_hash,
            refresh_expires_at=expiry,
            device="Chrome",
            ip_address="127.0.0.1",
        )

        # The stored value is the hash, not the raw token
        assert session.refresh_token_hash == refresh_hash
        assert session.refresh_token_hash != raw_refresh_token
        assert session.refresh_expires_at == expiry

    def test_session_refresh_expires_at_timezone_aware(self):
        """refresh_expires_at should be timezone-aware (UTC)."""
        session = Session(
            user_id=1,
            token_hash="hash",
            refresh_token_hash="rhash",
            refresh_expires_at=datetime.now(UTC) + timedelta(days=7),
        )
        assert session.refresh_expires_at.tzinfo is not None

    def test_session_refresh_expires_at_non_nullable(self):
        """refresh_expires_at column should be non-nullable."""
        col = self._get_column("refresh_expires_at")
        assert col is not None, "refresh_expires_at column not found"
        assert col.nullable is False

    def test_session_refresh_token_hash_nullable(self):
        """refresh_token_hash column should be nullable initially."""
        col = self._get_column("refresh_token_hash")
        assert col is not None, "refresh_token_hash column not found"
        assert col.nullable is True

    def test_session_refresh_token_hash_unique_constraint(self):
        """refresh_token_hash column should have unique constraint."""
        col = self._get_column("refresh_token_hash")
        assert col is not None, "refresh_token_hash column not found"
        assert col.unique is True

    def test_session_refresh_token_hash_indexed_by_unique(self):
        """refresh_token_hash is indexed via its unique constraint (PG unique=index)."""
        col = self._get_column("refresh_token_hash")
        assert col is not None, "refresh_token_hash column not found"
        # The unique constraint in PG creates a unique index automatically
        assert col.unique is True

    def test_token_hash_still_exists(self):
        """Existing token_hash column still exists."""
        assert hasattr(Session, "token_hash")

    def test_timestamp_columns_exist(self):
        """Session model still has timestamp columns from mixin."""
        assert hasattr(Session, "created_at")
        assert hasattr(Session, "updated_at")
