import base64
import os

import pytest

from app.domains.smart_home.crypto import (
    SmartHomeSecretKeyInvalidError,
    SmartHomeSecretKeyMissingError,
    SmartHomeTokenDecryptError,
    decrypt_token,
    encrypt_token,
)


def _secret() -> str:
    return base64.urlsafe_b64encode(os.urandom(32)).decode("ascii")


def test_encrypt_decrypt_token_round_trip():
    secret = _secret()
    encrypted = encrypt_token("ha-token", secret)

    assert encrypted != "ha-token"
    assert decrypt_token(encrypted, secret) == "ha-token"


def test_encrypt_requires_secret():
    with pytest.raises(SmartHomeSecretKeyMissingError, match="SMART_HOME_SECRET_KEY"):
        encrypt_token("ha-token", "")


def test_encrypt_rejects_invalid_secret_key():
    with pytest.raises(SmartHomeSecretKeyInvalidError, match="valid Fernet key"):
        encrypt_token("ha-token", "not-a-fernet-key")


def test_decrypt_rejects_wrong_secret():
    encrypted = encrypt_token("ha-token", _secret())

    with pytest.raises(SmartHomeTokenDecryptError, match="cannot be decrypted"):
        decrypt_token(encrypted, _secret())
