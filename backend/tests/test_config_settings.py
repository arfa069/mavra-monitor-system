import pytest
from app.config import Settings


def test_allowed_origins_default():
    settings = Settings(jwt_secret_key="dummy-secret-key-for-test-allowed-origins")
    assert settings.allowed_origins == ["http://localhost:3000", "http://127.0.0.1:3000"]
    assert settings.product_crawl_concurrency == 1


def test_allowed_origins_comma_separated():
    settings = Settings(
        jwt_secret_key="dummy-secret-key-for-test-allowed-origins",
        allowed_origins="http://example.com, http://example.org,http://example.net",
    )
    assert settings.allowed_origins == [
        "http://example.com",
        "http://example.org",
        "http://example.net",
    ]


def test_allowed_origins_json_list():
    settings = Settings(
        jwt_secret_key="dummy-secret-key-for-test-allowed-origins",
        allowed_origins='["http://example.com", "http://example.org"]',
    )
    # Pydantic loads JSON list automatically, our validator should bypass it
    assert settings.allowed_origins == ["http://example.com", "http://example.org"]


def test_product_crawl_concurrency_rejects_zero():
    with pytest.raises(ValueError):
        Settings(
            jwt_secret_key="dummy-secret-key-for-test-allowed-origins",
            product_crawl_concurrency=0,
        )
