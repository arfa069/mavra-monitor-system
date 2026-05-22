"""Compatibility module alias for the dashboard API router."""

import sys
from importlib import import_module

_dashboard_router_module = import_module("app.domains.dashboard.router")
sys.modules[__name__] = _dashboard_router_module
