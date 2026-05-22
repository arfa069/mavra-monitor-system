"""Compatibility module alias for the jobs API router."""

import sys
from importlib import import_module

_jobs_router_module = import_module("app.domains.jobs.router")
sys.modules[__name__] = _jobs_router_module
