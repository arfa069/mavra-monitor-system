import json
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.platforms.taobao import TaobaoAdapter
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
    async def test_disabled_returns_error(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_enabled", False
        )
        result = await crawl_taobao_via_opencli(
            "https://item.taobao.com/item.htm?id=904308303683"
        )
        assert result.success is False
        assert "taobao_opencli_enabled is False" in result.error

    @pytest.mark.asyncio
    async def test_no_id_returns_error(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_enabled", True
        )
        result = await crawl_taobao_via_opencli("https://www.taobao.com/")
        assert result.success is False
        assert "Cannot extract item ID" in result.error

    @pytest.mark.asyncio
    async def test_successful_crawl(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_enabled", True
        )
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
            "app.platforms.taobao_opencli.settings.taobao_opencli_enabled", True
        )
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
            "app.platforms.taobao_opencli.settings.taobao_opencli_enabled", True
        )
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


class TestTaobaoAdapterOpencliIntegration:
    @pytest.mark.asyncio
    async def test_crawl_with_page_uses_opencli_when_successful(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_enabled", True
        )
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_timeout_seconds", 30.0
        )

        output = json.dumps([
            {"field": "商品名称", "value": "测试商品"},
            {"field": "价格", "value": "¥43.05"},
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

        class FakePage:
            goto_calls = []

            async def goto(self, url, **kwargs):
                FakePage.goto_calls.append(url)

            async def wait_for_selector(self, *args, **kwargs):
                pass

            async def evaluate(self, *args):
                pass

            async def wait_for_timeout(self, *args):
                pass

        adapter = TaobaoAdapter()
        page = FakePage()
        result = await adapter.crawl_with_page(
            "https://item.taobao.com/item.htm?id=904308303683", page
        )

        assert result["success"] is True
        assert result["price"] == "43.05"
        assert result["title"] == "测试商品"
        assert FakePage.goto_calls == []

    @pytest.mark.asyncio
    async def test_crawl_with_page_falls_back_to_playwright(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_enabled", True
        )
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_timeout_seconds", 30.0
        )

        mock_proc = MagicMock()
        mock_proc.returncode = 1
        mock_proc.communicate = AsyncMock(return_value=(b"", b"error"))

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            "app.platforms.taobao_opencli.asyncio.create_subprocess_shell",
            mock_create_subprocess_shell,
        )

        adapter = TaobaoAdapter()

        class FakePage:
            goto_calls = []
            url = "https://item.taobao.com/item.htm?id=904308303683"

            async def goto(self, url, **kwargs):
                FakePage.goto_calls.append(url)

            async def wait_for_selector(self, *args, **kwargs):
                pass

            async def evaluate(self, *args):
                pass

            async def wait_for_timeout(self, *args):
                pass

        page = FakePage()
        _ = await adapter.crawl_with_page(
            "https://item.taobao.com/item.htm?id=904308303683", page
        )
        assert FakePage.goto_calls == ["https://item.taobao.com/item.htm?id=904308303683"]

    @pytest.mark.asyncio
    async def test_crawl_with_page_disabled_skips_opencli(self, monkeypatch):
        monkeypatch.setattr(
            "app.platforms.taobao_opencli.settings.taobao_opencli_enabled", False
        )

        adapter = TaobaoAdapter()

        class FakePage:
            goto_calls = []
            url = "https://item.taobao.com/item.htm?id=904308303683"

            async def goto(self, url, **kwargs):
                FakePage.goto_calls.append(url)

            async def wait_for_selector(self, *args, **kwargs):
                pass

            async def evaluate(self, *args):
                pass

            async def wait_for_timeout(self, *args):
                pass

        page = FakePage()
        _ = await adapter.crawl_with_page(
            "https://item.taobao.com/item.htm?id=904308303683", page
        )
        assert FakePage.goto_calls == ["https://item.taobao.com/item.htm?id=904308303683"]
