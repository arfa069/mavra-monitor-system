"""Compatibility module alias for the products API router."""

import sys
from importlib import import_module

_products_router_module = import_module("app.domains.products.router")
sys.modules[__name__] = _products_router_module
