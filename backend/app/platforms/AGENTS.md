# Platform Adapters Guide

## OVERVIEW

平台爬虫适配层：商品用 Playwright/CDP，职位优先 HTTP + `curl_cffi`，Boss 用 CloakBrowser 刷新 cookie。

## WHERE TO LOOK

| Platform             | Location                             | Notes                                              |
| -------------------- | ------------------------------------ | -------------------------------------------------- |
| Base product adapter | `base.py`                            | Browser lifecycle, navigation, extraction contract |
| JD/Taobao OpenCLI    | `jd_opencli.py`, `taobao_opencli.py` | Product anti-bot helper paths                      |
| Boss                 | `boss_cloak_experimental.py`         | Active Boss path; cookie refresh + serial HTTP     |
| 51job                | `job51.py`                           | `curl_cffi` search + HTML detail parsing           |
| Liepin               | `liepin.py`                          | HTTP search/detail; should not open browser tabs   |
| Strategies           | `strategies/*.py`                    | Price extraction strategies                        |
| Middleware           | `middleware/cookie_injection.py`     | Optional JD cookie fallback injection              |

## CONVENTIONS

- Product adapters own extraction logic; browser/profile lifecycle should stay in crawling domain when profile-managed.
- Boss list/detail requests stay serial and browser-like via `curl_cffi` impersonation.
- Liepin search posts to `api-c.liepin.com`; detail parsing covers `/job/` and `/a/` URLs.
- `JD_COOKIE` is emergency fallback only when explicitly enabled.
- Runtime logs under `backend/logs/` are for troubleshooting and must remain gitignored.

## ANTI-PATTERNS

- Do not add generic concurrent detail fetching to Boss.
- Do not make Liepin depend on browser tabs for the normal path.
- Do not inject cookies unless the matching fallback feature flag is enabled.
- Do not leak cookies/security IDs/webhooks in adapter logs.
- Do not use `networkidle` as a default page-load strategy for product pages.

## VERIFY

```powershell
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; pytest tests/test_boss_cloak_experimental.py tests/test_liepin_adapter.py tests/test_liepin_pipeline.py tests/test_jd_opencli.py tests/test_taobao_opencli.py tests/test_cdp_security.py"
powershell.exe -Command "cd C:/Users/arfac/price-monitor/backend; ruff check app/platforms tests/test_boss_cloak_experimental.py tests/test_liepin_adapter.py"
```
