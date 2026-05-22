"""Compatibility module alias for the admin API routers."""

import sys
from importlib import import_module

_admin_router_module = import_module("app.domains.admin.router")
sys.modules[__name__] = _admin_router_module
