import subprocess
import sys
from pathlib import Path


def test_crawling_service_import_does_not_require_browser_manager():
    backend_root = Path(__file__).resolve().parents[1]
    code = """
import importlib.abc
import sys


class BlockBrowserManager(importlib.abc.MetaPathFinder):
    def find_spec(self, fullname, path=None, target=None):
        if fullname == "app.domains.crawling.browser_manager":
            raise ModuleNotFoundError(fullname)
        return None


sys.meta_path.insert(0, BlockBrowserManager())
import app.domains.crawling.service
"""

    subprocess.run(
        [sys.executable, "-c", code],
        check=True,
        cwd=backend_root,
    )
