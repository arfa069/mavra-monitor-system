"""Compatibility module alias for the crawling API router."""

import sys
from importlib import import_module

_crawl_router_module = import_module("app.domains.crawling.router")
sys.modules[__name__] = _crawl_router_module
