"""Compatibility module alias for the WeChat authentication API router."""

import sys
from importlib import import_module

_wechat_router_module = import_module("app.domains.auth.wechat_router")
sys.modules[__name__] = _wechat_router_module
