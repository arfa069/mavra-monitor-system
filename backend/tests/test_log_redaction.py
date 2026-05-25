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


def test_redact_payload_handles_sets():
    from app.core.log_redaction import redact_payload

    # Sets of non-container items pass through unchanged.
    result = redact_payload({"tags": {"a", "b"}})
    assert result == {"tags": {"a", "b"}}
    assert isinstance(result["tags"], set)


def test_redact_payload_handles_plain_strings():
    from app.core.log_redaction import redact_payload

    assert redact_payload(None) is None
    assert redact_payload(42) == 42
    assert redact_payload("safe text") == "safe text"
