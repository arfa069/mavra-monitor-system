"""Compatibility module alias for the config API router."""

import sys
from importlib import import_module

_config_router_module = import_module("app.domains.config.router")
sys.modules[__name__] = _config_router_module
