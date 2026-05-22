"""Compatibility module alias for the alerts API router."""

import sys
from importlib import import_module

_alerts_router_module = import_module("app.domains.alerts.router")
sys.modules[__name__] = _alerts_router_module
