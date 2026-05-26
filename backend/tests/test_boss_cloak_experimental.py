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
