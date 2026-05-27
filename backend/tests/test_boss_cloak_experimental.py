def test_boss_anti_bot_codes_are_classified():
    from app.platforms.boss_cloak_experimental import classify_boss_failure

    assert classify_boss_failure({"code": 36}) == "anti_bot"
    assert classify_boss_failure({"code": 37}) == "anti_bot"
    assert classify_boss_failure({"code": 38}) == "anti_bot"
    assert classify_boss_failure({"code": 0}) is None


def test_boss_cookie_refresh_failure_returns_category(monkeypatch):
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    adapter = BossCloakExperimentalAdapter(profile_dir="profile")
    adapter._cookie_refresh_failures = 2

    assert adapter._profile_failure_category() == "cookie_refresh_failed"


def test_boss_cookie_refresh_reload_abort_falls_back_to_search_page():
    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    class FakePage:
        url = "https://www.zhipin.com/web/geek/jobs?query=python"

        def __init__(self):
            self.goto_calls = []

        def reload(self, **kwargs):
            raise RuntimeError("Page.reload: net::ERR_ABORTED; maybe frame was detached?")

        def goto(self, url, **kwargs):
            self.goto_calls.append((url, kwargs))

    adapter = BossCloakExperimentalAdapter(profile_dir="profile", log_enabled=False)
    adapter._search_page = "https://www.zhipin.com/web/geek/jobs?query=python&city=101280100"
    page = FakePage()

    adapter._navigate_for_cookie_refresh(page, "code_36_page_1")

    assert page.goto_calls == [
        (
            "https://www.zhipin.com/web/geek/jobs?query=python&city=101280100",
            {"wait_until": "domcontentloaded", "timeout": 45000},
        )
    ]


def test_boss_cookie_refresh_reload_unexpected_error_still_raises():
    import pytest

    from app.platforms.boss_cloak_experimental import BossCloakExperimentalAdapter

    class FakePage:
        url = "https://www.zhipin.com/web/geek/jobs?query=python"

        def reload(self, **kwargs):
            raise RuntimeError("Page.reload: certificate failed")

    adapter = BossCloakExperimentalAdapter(profile_dir="profile", log_enabled=False)

    with pytest.raises(RuntimeError, match="certificate failed"):
        adapter._navigate_for_cookie_refresh(FakePage(), "code_36_page_1")
