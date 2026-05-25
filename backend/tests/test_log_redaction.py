def test_redact_payload_masks_sensitive_keys():
    from app.core.log_redaction import redact_payload

    payload = {
        "cookie": "a=b",
        "headers": {"Authorization": "Bearer secret", "User-Agent": "Chrome"},
        "webhook_url": "https://open.feishu.cn/hook/secret",
        "securityId": "abcdef1234567890",
    }

    assert redact_payload(payload) == {
        "cookie": "***REDACTED***",
        "headers": {"Authorization": "***REDACTED***", "User-Agent": "Chrome"},
        "webhook_url": "***REDACTED***",
        "securityId": "abcdef12***",
    }


def test_redact_payload_handles_nested_lists():
    from app.core.log_redaction import redact_payload

    payload = {"items": [{"token": "secret"}, {"name": "safe"}]}

    assert redact_payload(payload) == {
        "items": [{"token": "***REDACTED***"}, {"name": "safe"}]
    }
