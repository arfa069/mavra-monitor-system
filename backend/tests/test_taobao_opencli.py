import json
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.platforms.taobao_opencli import (
    crawl_taobao_via_opencli,
    extract_item_id,
)


class TestExtractItemId:
    def test_extract_item_taobao(self):
        assert extract_item_id("https://item.taobao.com/item.htm?id=904308303683") == "904308303683"

    def test_extract_detail_tmall(self):
        assert extract_item_id("https://detail.tmall.com/item.htm?id=904308303683&skuId=123") == "904308303683"

    def test_extract_chaoshi_tmall(self):
        assert extract_item_id("https://chaoshi.detail.tmall.com/item.htm?id=904308303683") == "904308303683"

    def test_extract_no_id(self):
        assert extract_item_id("https://www.taobao.com/") is None

    def test_extract_non_taobao_url(self):
        assert extract_item_id("https://item.jd.com/100147630258.html") is None


class TestCrawlTaobaoViaOpencli:
    @pytest.mark.asyncio
    async def test_no_id_returns_error(self, monkeypatch):
        result = await crawl_taobao_via_opencli("https://www.taobao.com/")
        assert result.success is False
        assert "Cannot extract item ID" in result.error

    @pytest.mark.asyncio
    async def test_successful_crawl(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_timeout_seconds", 30.0
        )

        output = json.dumps([
            {"field": "商品名称", "value": "测试商品"},
            {"field": "价格", "value": "¥43.05"},
            {"field": "ID", "value": "904308303683"},
        ]).encode()

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.communicate = AsyncMock(return_value=(output, b""))

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            "app.platforms.taobao_opencli.asyncio.create_subprocess_shell",
            mock_create_subprocess_shell,
        )

        result = await crawl_taobao_via_opencli(
            "https://item.taobao.com/item.htm?id=904308303683"
        )
        assert result.success is True
        assert result.price == "43.05"
        assert result.title == "测试商品"

    @pytest.mark.asyncio
    async def test_nonzero_exit_code(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_timeout_seconds", 30.0
        )

        mock_proc = MagicMock()
        mock_proc.returncode = 1
        mock_proc.communicate = AsyncMock(return_value=(b"", b"some error"))

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            "app.platforms.taobao_opencli.asyncio.create_subprocess_shell",
            mock_create_subprocess_shell,
        )

        result = await crawl_taobao_via_opencli(
            "https://item.taobao.com/item.htm?id=904308303683"
        )
        assert result.success is False
        assert "some error" in result.error

    @pytest.mark.asyncio
    async def test_timeout(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_timeout_seconds", 0.01
        )

        async def mock_communicate():
            import asyncio
            await asyncio.sleep(10)
            return b"", b""

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.communicate = mock_communicate

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            "app.platforms.taobao_opencli.asyncio.create_subprocess_shell",
            mock_create_subprocess_shell,
        )

        result = await crawl_taobao_via_opencli(
            "https://item.taobao.com/item.htm?id=904308303683"
        )
        assert result.success is False
        assert "timed out" in result.error.lower()


