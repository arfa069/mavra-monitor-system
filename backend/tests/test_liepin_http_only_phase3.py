def test_liepin_has_no_cdp_fallback_methods():
    import app.platforms.liepin as liepin

    assert not hasattr(liepin.LiepinAdapter, "_crawl_via_cdp")
    assert not hasattr(liepin.LiepinAdapter, "_crawl_detail_via_cdp")


def test_liepin_classifies_challenge_html():
    from app.platforms.liepin import classify_liepin_failure

    assert classify_liepin_failure(status_code=200, text="<html>安全验证 passport</html>") == "challenge"


def test_liepin_classifies_xsrf_response():
    from app.platforms.liepin import classify_liepin_failure

    assert classify_liepin_failure(status_code=403, text="XSRF token invalid") == "xsrf"
