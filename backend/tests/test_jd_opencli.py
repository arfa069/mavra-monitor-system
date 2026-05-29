import json
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.platforms.jd_opencli import (
    crawl_jd_via_opencli,
    extract_sku,
)


class TestExtractSku:
    def test_extract_item_jd_com(self):
        assert extract_sku('https://item.jd.com/100147630258.html') == '100147630258'

    def test_extract_item_m_jd_com(self):
        assert extract_sku('https://item.m.jd.com/product/100147630258.html') == '100147630258'

    def test_extract_with_query_params(self):
        assert extract_sku('https://item.jd.com/12345.html?cu=true') == '12345'

    def test_extract_no_sku(self):
        assert extract_sku('https://www.jd.com/') is None

    def test_extract_non_jd_url(self):
        assert extract_sku('https://item.taobao.com/item.htm?id=123') is None


class TestCrawlJdViaOpencli:
    @pytest.mark.asyncio
    async def test_no_sku_returns_error(self, monkeypatch):
        result = await crawl_jd_via_opencli('https://www.jd.com/')
        assert result.success is False
        assert 'Cannot extract SKU' in result.error

    @pytest.mark.asyncio
    async def test_successful_crawl(self, monkeypatch):
        monkeypatch.setattr(
            'app.platforms.jd_opencli.settings.jd_opencli_command', 'opencli'
        )
        monkeypatch.setattr(
            'app.platforms.jd_opencli.settings.jd_opencli_timeout_seconds', 30.0
        )

        output = json.dumps([{
            'price': '3198.9',
            'title': 'AMD 9800X3D',
            'shop': 'AMD Store',
            'pageState': {
                'isLoginPage': False,
                'hasSecurityChallenge': False,
                'looksBlocked': False,
            },
        }]).encode()

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.communicate = AsyncMock(return_value=(output, b''))

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            'app.platforms.jd_opencli.asyncio.create_subprocess_shell',
            mock_create_subprocess_shell,
        )

        result = await crawl_jd_via_opencli(
            'https://item.jd.com/100147630258.html'
        )
        assert result.success is True
        assert result.price == '3198.9'
        assert result.title == 'AMD 9800X3D'
        assert result.shop == 'AMD Store'
        assert result.is_login_page is False
        assert result.has_security_challenge is False
        assert result.looks_blocked is False

    @pytest.mark.asyncio
    async def test_detects_login_page(self, monkeypatch):
        monkeypatch.setattr(
            'app.platforms.jd_opencli.settings.jd_opencli_timeout_seconds', 30.0
        )

        output = json.dumps([{
            'price': '',
            'title': '',
            'shop': '',
            'pageState': {
                'isLoginPage': True,
                'hasSecurityChallenge': False,
                'looksBlocked': False,
            },
        }]).encode()

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.communicate = AsyncMock(return_value=(output, b''))

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            'app.platforms.jd_opencli.asyncio.create_subprocess_shell',
            mock_create_subprocess_shell,
        )

        result = await crawl_jd_via_opencli(
            'https://item.jd.com/100147630258.html'
        )
        assert result.success is True
        assert result.price == ''
        assert result.is_login_page is True

    @pytest.mark.asyncio
    async def test_detects_security_challenge(self, monkeypatch):
        monkeypatch.setattr(
            'app.platforms.jd_opencli.settings.jd_opencli_timeout_seconds', 30.0
        )

        output = json.dumps([{
            'price': '',
            'pageState': {
                'isLoginPage': False,
                'hasSecurityChallenge': True,
                'looksBlocked': False,
            },
        }]).encode()

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.communicate = AsyncMock(return_value=(output, b''))

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            'app.platforms.jd_opencli.asyncio.create_subprocess_shell',
            mock_create_subprocess_shell,
        )

        result = await crawl_jd_via_opencli(
            'https://item.jd.com/100147630258.html'
        )
        assert result.has_security_challenge is True

    @pytest.mark.asyncio
    async def test_detects_looks_blocked(self, monkeypatch):
        monkeypatch.setattr(
            'app.platforms.jd_opencli.settings.jd_opencli_timeout_seconds', 30.0
        )

        output = json.dumps([{
            'price': '',
            'pageState': {
                'isLoginPage': False,
                'hasSecurityChallenge': False,
                'looksBlocked': True,
            },
        }]).encode()

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.communicate = AsyncMock(return_value=(output, b''))

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            'app.platforms.jd_opencli.asyncio.create_subprocess_shell',
            mock_create_subprocess_shell,
        )

        result = await crawl_jd_via_opencli(
            'https://item.jd.com/100147630258.html'
        )
        assert result.looks_blocked is True

    @pytest.mark.asyncio
    async def test_command_not_found(self, monkeypatch):
        monkeypatch.setattr(
            'app.platforms.jd_opencli.settings.jd_opencli_command',
            'nonexistent-opencli',
        )

        async def mock_create_subprocess_shell(*args, **kwargs):
            raise FileNotFoundError('nonexistent-opencli')

        monkeypatch.setattr(
            'app.platforms.jd_opencli.asyncio.create_subprocess_shell',
            mock_create_subprocess_shell,
        )

        result = await crawl_jd_via_opencli(
            'https://item.jd.com/100147630258.html'
        )
        assert result.success is False
        assert 'command not found' in result.error

    @pytest.mark.asyncio
    async def test_nonzero_exit_code(self, monkeypatch):
        monkeypatch.setattr(
            'app.platforms.jd_opencli.settings.jd_opencli_timeout_seconds', 30.0
        )

        mock_proc = MagicMock()
        mock_proc.returncode = 1
        mock_proc.communicate = AsyncMock(
            return_value=(b'', b'Browser Bridge not connected')
        )

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            'app.platforms.jd_opencli.asyncio.create_subprocess_shell',
            mock_create_subprocess_shell,
        )

        result = await crawl_jd_via_opencli(
            'https://item.jd.com/100147630258.html'
        )
        assert result.success is False
        assert 'Browser Bridge not connected' in result.error

    @pytest.mark.asyncio
    async def test_timeout(self, monkeypatch):
        monkeypatch.setattr(
            'app.platforms.jd_opencli.settings.jd_opencli_timeout_seconds', 0.01
        )

        async def mock_communicate():
            import asyncio
            await asyncio.sleep(10)
            return b'', b''

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.communicate = mock_communicate

        async def mock_create_subprocess_shell(*args, **kwargs):
            return mock_proc

        monkeypatch.setattr(
            'app.platforms.jd_opencli.asyncio.create_subprocess_shell',
            mock_create_subprocess_shell,
        )

        result = await crawl_jd_via_opencli(
            'https://item.jd.com/100147630258.html'
        )
        assert result.success is False
        assert 'timed out' in result.error.lower()


