"""Compatibility module alias for the events API router."""

import sys
from importlib import import_module

_events_router_module = import_module("app.domains.events.router")
sys.modules[__name__] = _events_router_module
