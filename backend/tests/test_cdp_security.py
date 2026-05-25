import pytest


@pytest.mark.parametrize(
    "url",
    [
        "http://127.0.0.1:9222",
        "http://localhost:9222",
        "http://[::1]:9222",
    ],
)
def test_local_cdp_urls_allowed(url):
    from app.core.cdp_security import validate_cdp_url

    validate_cdp_url(url, allow_non_local=False)


@pytest.mark.parametrize(
    "url",
    [
        "http://0.0.0.0:9222",
        "http://192.168.1.10:9222",
        "http://8.8.8.8:9222",
    ],
)
def test_non_local_cdp_urls_rejected(url):
    from app.core.cdp_security import validate_cdp_url

    with pytest.raises(ValueError, match="CDP URL must be local"):
        validate_cdp_url(url, allow_non_local=False)


def test_non_local_cdp_urls_allowed_with_explicit_override():
    from app.core.cdp_security import validate_cdp_url

    validate_cdp_url("http://192.168.1.10:9222", allow_non_local=True)


def test_empty_cdp_url_rejected():
    from app.core.cdp_security import validate_cdp_url

    with pytest.raises(ValueError, match="CDP URL is empty"):
        validate_cdp_url("")


def test_cdp_url_without_host_rejected():
    from app.core.cdp_security import validate_cdp_url

    with pytest.raises(ValueError, match="CDP URL must include a host"):
        validate_cdp_url("http://")
