"""Encryption helpers for Home Assistant tokens."""
from cryptography.fernet import Fernet, InvalidToken


class SmartHomeCryptoError(RuntimeError):
    """Raised when smart home token encryption or decryption fails."""


def _fernet(secret_key: str) -> Fernet:
    if not secret_key:
        raise SmartHomeCryptoError("SMART_HOME_SECRET_KEY is required to store Home Assistant tokens")
    try:
        return Fernet(secret_key.encode("ascii"))
    except Exception as exc:
        raise SmartHomeCryptoError("SMART_HOME_SECRET_KEY must be a valid Fernet key") from exc


def encrypt_token(token: str, secret_key: str) -> str:
    return _fernet(secret_key).encrypt(token.encode("utf-8")).decode("ascii")


def decrypt_token(encrypted_token: str, secret_key: str) -> str:
    try:
        return _fernet(secret_key).decrypt(encrypted_token.encode("ascii")).decode("utf-8")
    except InvalidToken as exc:
        raise SmartHomeCryptoError("Failed to decrypt Home Assistant token") from exc
