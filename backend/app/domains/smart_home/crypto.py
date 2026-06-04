"""Encryption helpers for Home Assistant tokens."""
from cryptography.fernet import Fernet, InvalidToken


class SmartHomeCryptoError(RuntimeError):
    """Raised when smart home token encryption or decryption fails."""


class SmartHomeSecretKeyMissingError(SmartHomeCryptoError):
    """Raised when the smart home encryption key is not configured."""


class SmartHomeSecretKeyInvalidError(SmartHomeCryptoError):
    """Raised when the smart home encryption key is not a valid Fernet key."""


class SmartHomeTokenDecryptError(SmartHomeCryptoError):
    """Raised when an encrypted Home Assistant token cannot be decrypted."""


def _fernet(secret_key: str) -> Fernet:
    if not secret_key:
        raise SmartHomeSecretKeyMissingError(
            "SMART_HOME_SECRET_KEY is not configured"
        )
    try:
        return Fernet(secret_key.encode("ascii"))
    except Exception as exc:
        raise SmartHomeSecretKeyInvalidError(
            "SMART_HOME_SECRET_KEY is not a valid Fernet key"
        ) from exc


def encrypt_token(token: str, secret_key: str) -> str:
    return _fernet(secret_key).encrypt(token.encode("utf-8")).decode("ascii")


def decrypt_token(encrypted_token: str, secret_key: str) -> str:
    try:
        return _fernet(secret_key).decrypt(encrypted_token.encode("ascii")).decode("utf-8")
    except InvalidToken as exc:
        raise SmartHomeTokenDecryptError(
            "Stored Home Assistant token cannot be decrypted with the current SMART_HOME_SECRET_KEY"
        ) from exc
