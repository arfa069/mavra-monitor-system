"""Tests for JWT token creation, decoding, refresh token, and CSRF helpers."""
from __future__ import annotations

from datetime import UTC, datetime, timedelta

from jose import jwt

from app.core.tokens import (
    ALGORITHM,
    SECRET_KEY,
    create_access_token,
    create_access_token_sid,
    create_csrf_token,
    create_refresh_token,
    decode_access_token,
    decode_access_token_strict,
    hash_token,
)

# ── Access Token (new standard) ──


class TestCreateAccessTokenSid:
    """Tests for create_access_token_sid(user_id, username, session_id)."""

    def test_returns_string_jwt_with_three_parts(self):
        """create_access_token_sid 返回标准的 JWT 字符串。"""
        token = create_access_token_sid(user_id=1, username="testuser", session_id=42)
        assert isinstance(token, str)
        assert token.count(".") == 2

    def test_payload_contains_required_claims(self):
        """新 access token 包含 sub, username, sid, typ 和 exp 声明。"""
        token = create_access_token_sid(user_id=1, username="testuser", session_id=42)
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        assert payload["sub"] == "1"
        assert payload["username"] == "testuser"
        assert payload["sid"] == 42
        assert payload["typ"] == "access"
        assert "exp" in payload

    def test_expiry_uses_config_default_of_15_minutes(self):
        """新 access token 默认过期时间使用配置的 15 分钟。"""
        before = datetime.now(UTC)
        token = create_access_token_sid(user_id=1, username="testuser", session_id=42)
        after = datetime.now(UTC)

        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        exp_dt = datetime.fromtimestamp(payload["exp"], tz=UTC)

        assert exp_dt >= before + timedelta(minutes=14)
        assert exp_dt <= after + timedelta(minutes=16)


# ── Legacy create_access_token ──


class TestCreateAccessTokenLegacy:
    """Tests for the legacy create_access_token(data, expires_delta) (backward compat)."""

    def test_returns_string_jwt(self):
        """create_access_token 返回标准 JWT 字符串。"""
        data = {"sub": "testuser"}
        token = create_access_token(data)
        assert isinstance(token, str)
        assert token.count(".") == 2

    def test_accepts_custom_payload(self):
        """create_access_token 接受任意自定义 payload。"""
        data = {"sub": "testuser", "extra": "value", "temp": True}
        token = create_access_token(data)
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        assert payload["sub"] == "testuser"
        assert payload["extra"] == "value"
        assert payload["temp"] is True

    def test_custom_expiry(self):
        """create_access_token 支持自定义过期时间。"""
        data = {"sub": "testuser"}
        token = create_access_token(data, expires_delta=timedelta(hours=2))
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        exp_dt = datetime.fromtimestamp(payload["exp"], tz=UTC)
        assert exp_dt >= datetime.now(UTC) + timedelta(hours=1, minutes=59)


# ── decode_access_token (backward compat) ──


class TestDecodeAccessToken:
    """Tests for the existing decode_access_token (backward compat)."""

    def test_decodes_valid_token(self):
        """decode_access_token 能解码有效 token。"""
        token = create_access_token_sid(user_id=1, username="testuser", session_id=42)
        payload = decode_access_token(token)
        assert payload is not None
        assert payload["sub"] == "1"
        assert payload["sid"] == 42

    def test_returns_none_for_expired_token(self):
        """过期 token 返回 None。"""
        data = {"sub": "testuser"}
        token = create_access_token(data, expires_delta=timedelta(seconds=-1))
        payload = decode_access_token(token)
        assert payload is None

    def test_returns_none_for_invalid_signature(self):
        """错误签名的 token 返回 None。"""
        fake_token = jwt.encode({"sub": "testuser"}, "wrong-secret", algorithm="HS256")
        payload = decode_access_token(fake_token)
        assert payload is None


# ── decode_access_token_strict ──


class TestDecodeAccessTokenStrict:
    """Tests for decode_access_token_strict with claim validation."""

    def test_valid_token_succeeds(self):
        """严格解码接受合法的 access token。"""
        token = create_access_token_sid(user_id=1, username="testuser", session_id=42)
        payload = decode_access_token_strict(token)
        assert payload is not None
        assert payload["sub"] == "1"
        assert payload["sid"] == 42
        assert payload["typ"] == "access"

    def test_rejects_expired_token(self):
        """严格解码拒绝过期 token。"""
        data = {"sub": "1", "username": "testuser", "sid": 42, "typ": "access"}
        token = create_access_token(data, expires_delta=timedelta(seconds=-1))
        payload = decode_access_token_strict(token)
        assert payload is None

    def test_rejects_token_without_typ_claim(self):
        """缺少 typ 声明的 token 被拒绝。"""
        token = create_access_token({"sub": "1", "username": "testuser", "sid": 42})
        payload = decode_access_token_strict(token)
        assert payload is None

    def test_rejects_token_with_wrong_typ(self):
        """typ 不为 "access" 的 token 被拒绝。"""
        data = {"sub": "1", "username": "testuser", "sid": 42, "typ": "refresh"}
        token = create_access_token(data)
        payload = decode_access_token_strict(token)
        assert payload is None

    def test_rejects_token_without_sub(self):
        """缺少 sub 声明的 token 被拒绝。"""
        token = create_access_token({"sid": 42, "typ": "access"})
        payload = decode_access_token_strict(token)
        assert payload is None

    def test_rejects_token_without_sid(self):
        """缺少 sid 声明的 token 被拒绝。"""
        token = create_access_token({"sub": "1", "typ": "access"})
        payload = decode_access_token_strict(token)
        assert payload is None

    def test_rejects_invalid_signature(self):
        """错误签名的 token 被拒绝。"""
        fake_token = jwt.encode(
            {"sub": "1", "username": "testuser", "sid": 42, "typ": "access"},
            "wrong-secret",
            algorithm="HS256",
        )
        payload = decode_access_token_strict(fake_token)
        assert payload is None

    def test_rejects_tampered_payload(self):
        """篡改 payload 的 token 被拒绝。"""
        # 用错误密钥编码来模拟篡改
        modified_payload = {"sub": "999", "username": "hacker", "sid": 1, "typ": "access"}
        fake_token = jwt.encode(modified_payload, "hacker-secret", algorithm="HS256")
        payload = decode_access_token_strict(fake_token)
        assert payload is None


# ── Refresh Token ──


class TestRefreshToken:
    """Tests for opaque refresh token helpers."""

    def test_create_refresh_token_returns_string(self):
        """create_refresh_token 返回字符串。"""
        token = create_refresh_token()
        assert isinstance(token, str)
        # token_urlsafe(48) = 64 chars
        assert len(token) == 64

    def test_create_refresh_tokens_are_unique(self):
        """每次生成的 refresh token 是唯一的。"""
        tokens = {create_refresh_token() for _ in range(100)}
        assert len(tokens) == 100

    def test_hash_token_is_deterministic(self):
        """相同 token 每次 hash 结果相同。"""
        token = "test-refresh-token-value"
        hash1 = hash_token(token)
        hash2 = hash_token(token)
        assert hash1 == hash2

    def test_hash_token_produces_sha256_hex(self):
        """hash_token 产生 64 字符的十六进制字符串。"""
        token = create_refresh_token()
        hashed = hash_token(token)
        assert len(hashed) == 64
        assert all(c in "0123456789abcdef" for c in hashed)

    def test_hash_token_does_not_embed_raw_token(self):
        """hash 值不包含原始 token 内容。"""
        token = create_refresh_token()
        hashed = hash_token(token)
        assert token not in hashed


# ── CSRF Token ──


class TestCsrfToken:
    """Tests for CSRF token helper."""

    def test_create_csrf_token_returns_string(self):
        """create_csrf_token 返回字符串。"""
        token = create_csrf_token()
        assert isinstance(token, str)
        # token_urlsafe(32) = 43 chars
        assert len(token) == 43

    def test_create_csrf_tokens_are_unique(self):
        """每次生成的 CSRF token 是唯一的。"""
        tokens = {create_csrf_token() for _ in range(100)}
        assert len(tokens) == 100
