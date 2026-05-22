"""Compatibility module alias for the authentication API router."""

import sys
from importlib import import_module

_auth_router_module = import_module("app.domains.auth.router")
sys.modules[__name__] = _auth_router_module
