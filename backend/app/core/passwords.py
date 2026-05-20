"""Password hashing and verification using bcrypt-sha256."""
from __future__ import annotations

import hashlib

import bcrypt

PASSWORD_HASH_PREFIX = "$bcrypt-sha256$"


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
