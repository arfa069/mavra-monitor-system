"""Validation tests for Feishu webhook destination allowlisting."""

import pytest
from pydantic import ValidationError

from app.schemas.user import UserConfigCreate, UserConfigUpdate

VALID_FEISHU_WEBHOOK = "https://open.feishu.cn/open-apis/bot/v2/hook/test-token"


def test_user_config_accepts_valid_feishu_webhook_url():
    config = UserConfigCreate(feishu_webhook_url=VALID_FEISHU_WEBHOOK)

    assert config.feishu_webhook_url == VALID_FEISHU_WEBHOOK


def test_user_config_accepts_empty_feishu_webhook_url():
    assert UserConfigCreate(feishu_webhook_url="").feishu_webhook_url == ""
    assert UserConfigUpdate(feishu_webhook_url=None).feishu_webhook_url is None


@pytest.mark.parametrize(
    "webhook_url",
    [
        "http://127.0.0.1/open-apis/bot/v2/hook/test-token",
        "https://127.0.0.1/open-apis/bot/v2/hook/test-token",
        "https://evil.example/open-apis/bot/v2/hook/test-token",
        "https://open.feishu.cn.evil.example/open-apis/bot/v2/hook/test-token",
        "https://open.feishu.cn/hook/test-token",
    ],
)
def test_user_config_rejects_non_feishu_webhook_destinations(webhook_url: str):
    with pytest.raises(ValidationError):
        UserConfigUpdate(feishu_webhook_url=webhook_url)
