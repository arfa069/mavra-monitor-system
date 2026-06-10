"""Password hashing and verification using bcrypt-sha256."""
from __future__ import annotations

import hashlib

import bcrypt

PASSWORD_HASH_PREFIX = "$bcrypt-sha256$"
PASSWORD_STRENGTH_ERROR = (
    "密码必须至少 10 位，并同时包含大写字母、小写字母、数字和特殊字符"
)


def validate_password_strength(password: str) -> str:
    """Validate password strength for new or changed credentials."""
    has_min_length = len(password) >= 10
    has_uppercase = any(char.isupper() for char in password)
    has_lowercase = any(char.islower() for char in password)
    has_digit = any(char.isdigit() for char in password)
    has_special = any(not char.isalnum() and not char.isspace() for char in password)

    if not (
        has_min_length
        and has_uppercase
        and has_lowercase
        and has_digit
        and has_special
    ):
        raise ValueError(PASSWORD_STRENGTH_ERROR)
    return password


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against a hashed password."""
    password_bytes = plain_password.encode("utf-8")
    if hashed_password.startswith(PASSWORD_HASH_PREFIX):
        digest = hashlib.sha256(password_bytes).digest()
        stored_hash = hashed_password[len(PASSWORD_HASH_PREFIX):].encode("utf-8")
        return bcrypt.checkpw(digest, stored_hash)

    try:
        return bcrypt.checkpw(password_bytes, hashed_password.encode("utf-8"))
    except ValueError:
        return False


def get_password_hash(password: str) -> str:
    """Hash a password using bcrypt-sha256."""
    digest = hashlib.sha256(password.encode("utf-8")).digest()
    return PASSWORD_HASH_PREFIX + bcrypt.hashpw(digest, bcrypt.gensalt()).decode("utf-8")
