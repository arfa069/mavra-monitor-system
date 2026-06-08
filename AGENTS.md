# PROJECT KNOWLEDGE BASE

**Generated:** 2026-06-09
**Commit:** 8ef8370a
**Branch:** main

<!-- gitnexus:start -->

# GitNexus — Code Intelligence

This project is indexed by GitNexus as **mavra-monitor-system** (8559 symbols, 15981 relationships, 300 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource                                              | Use for                                  |
| ----------------------------------------------------- | ---------------------------------------- |
| `gitnexus://repo/mavra-monitor-system/context`        | Codebase overview, check index freshness |
| `gitnexus://repo/mavra-monitor-system/clusters`       | All functional areas                     |
| `gitnexus://repo/mavra-monitor-system/processes`      | All execution flows                      |
| `gitnexus://repo/mavra-monitor-system/process/{name}` | Step-by-step execution trace             |

## CLI

| Task                                         | Read this skill file                                        |
| -------------------------------------------- | ----------------------------------------------------------- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md`       |
| Blast radius / "What breaks if I change X?"  | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?"             | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md`       |
| Rename / extract / split / refactor          | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md`     |
| Tools, resources, schema reference           | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md`           |
| Index, status, clean, wiki CLI commands      | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md`             |

<!-- gitnexus:end -->

## OVERVIEW

淘宝、京东、亚马逊价格监控 + Boss/51job/猎聘职位监控 + Home Assistant 智能家居控制。后端 FastAPI + PostgreSQL/Redis + Playwright/curl_cffi/CloakBrowser；前端 React/Vite/TypeScript/Ant Design + Figma Design System。

## STRUCTURE

```
mavra-monitor-system/
├── backend/                    # FastAPI, SQLAlchemy, crawlers, workers, tests
│   ├── app/main.py             # FastAPI app + lifespan + router mounting
│   ├── app/domains/            # business domains: crawling/jobs/products/auth/admin/smart_home/...
│   ├── app/platforms/          # Taobao/JD/Amazon/Boss/51job/Liepin adapters
│   └── tests/                  # pytest unit/integration/regression tests
├── frontend/                   # Vite React app
│   ├── src/App.tsx             # router/layout/theme composition
│   ├── src/features/           # feature-first modules
│   ├── src/shared/             # API client, auth context, layout, shared types
│   └── tests/e2e/              # Playwright E2E specs
├── doc/                        # living architecture/design docs
├── docs/                       # implementation plans and historical plans
├── scripts/start_server.ps1    # local backend/frontend/worker launcher
└── profiles/                   # runtime browser profiles; do not hand-edit
```

## WHERE TO LOOK

| Task                    | Location                                                                                                  | Notes                                                                                                |
| ----------------------- | --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Backend routes/lifespan | `backend/app/main.py`, `backend/app/domains/*/router.py`                                                  | Legacy, `/v1`, and `/api/v1` are mounted together                                                    |
| Product crawl           | `backend/app/domains/crawling`, `backend/app/platforms`                                                   | Playwright/CDP/profile-sensitive                                                                     |
| Job crawl               | `backend/app/domains/jobs`, `backend/app/platforms`                                                       | Boss uses CloakBrowser cookie refresh + `curl_cffi`; Liepin supports Chromium profile cookie loading |
| Smart home              | `backend/app/domains/smart_home`, `backend/app/models/smart_home.py`, `backend/app/schemas/smart_home.py` | Home Assistant config, entity control, SSE fanout, encrypted token storage                           |
| Auth/RBAC               | `backend/app/core/security.py`, `backend/app/core/permissions.py`, `doc/permission-architecture.md`       | Cookie-first + Bearer fallback                                                                       |
| Frontend routes         | `frontend/src/App.tsx`                                                                                    | Root redirects to `/jobs`                                                                            |
| Frontend API/auth       | `frontend/src/shared/api/client.ts`, `frontend/src/shared/contexts/AuthContext.tsx`                       | Axios injects CSRF and refreshes 401                                                                 |
| Design decisions        | `doc/DESIGN.md`, `frontend/src/styles/`                                                                   | Mandatory before UI changes                                                                          |
| Manual QA               | `backend/tests/manual_verification_checklist.md`                                                          | Browser evidence for UI/crawl-trigger changes                                                        |

## CODE MAP

| Area              | Key files                                                                                        | Role                                                  |
| ----------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| App bootstrap     | `backend/app/main.py`, `frontend/src/main.tsx`                                                   | Backend lifespan/router setup; React Query provider   |
| Crawl runtime     | `backend/app/domains/crawling/task_runner.py`, `task_store.py`, `backend/app/workers/crawler.py` | Durable task execution and worker loop                |
| Profile pool      | `backend/app/domains/crawling/profile_pool.py`, `browser_manager.py`                             | DB lease + browser session lifecycle                  |
| Platform adapters | `backend/app/platforms/*.py`                                                                     | Product/job platform extraction and anti-bot handling |
| Job domain        | `backend/app/domains/jobs/*`, `llm/*`                                                            | Job configs, crawl, notification, resume matching     |
| Frontend jobs     | `frontend/src/features/jobs/*`                                                                   | Largest UI feature: jobs, profiles, resumes, matching |
| Shared frontend   | `frontend/src/shared/*`                                                                          | Auth, API, layout, motion/theme primitives            |
| Shared utils      | `backend/app/utils/*.py`                                                                         | URL normalization, salary parsing, request helpers    |
| Shared core       | `backend/app/core/*.py`                                                                          | JSON utils, Redis client, sessions, event streaming   |

## COMMANDS

Run shell/test/lint commands through PowerShell on Windows.

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; pip install -e ."
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; alembic upgrade head"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system; powershell -ExecutionPolicy Bypass -File 'scripts/start_server.ps1'"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; pytest"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/backend; ruff check ."
```

Frontend:

```powershell
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run lint"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; npm run build"
powershell.exe -Command "cd C:/Users/arfac/Documents/mavra-monitor-system/frontend; $env:E2E_BASE_URL='http://localhost:3000'; npx playwright test tests/e2e/ --project=chromium"
```

## CONVENTIONS

- Coding changes should load the `karpathy-guidelines` skill before implementation.
- Default test user: `default` / `123456`; some manual docs mention `default123` / `123456`, verify actual seeded user before browser QA.
- Use UTC-aware timestamps: `datetime.now(timezone.utc)`.
- Compare prices with `Decimal`, not floats.
- `user_id=1` legacy assumptions remain in crawler/product/job code, but auth is multi-user.
- Browser auth is Cookie-first (`pm_access_token`, `pm_refresh_token`, `pm_csrf_token`); scripts may use Bearer fallback.
- API modules use `/api/v1` from frontend; Vite proxy strips `/api` before backend.
- `SMART_HOME_SECRET_KEY` must be set before saving a Home Assistant token; the smart-home routes use `smart_home:read`, `smart_home:control`, and `smart_home:configure`.

## ANTI-PATTERNS (THIS PROJECT)

- Do not use `uvicorn --reload` on Windows; it breaks Playwright subprocess handling.
- Do not manually rename/copy/delete `profiles/{key}`. Use Jobs → Profiles Management or `/v1/crawl-profiles`.
- Do not run two crawl/login sessions on the same profile directory at once.
- Do not treat `JD_COOKIE` as default; it is fallback only when `JD_COOKIE_FALLBACK_ENABLED=true`.
- Do not make Boss crawl use Edge CDP; active path is `BossCloakExperimentalAdapter`.
- Do not open browser tabs for normal Liepin crawl; it is HTTP-only via `api-c.liepin.com` + detail HTML parsing. Chromium profile cookies can be loaded under Windows via DPAPI, and detail requests are throttled with 5-10s random delays.
- Do not expose cookie/token/webhook/security fields in logs or event payloads.
- Do not claim validation passed unless the command/browser check actually ran.

## DESIGN SYSTEM

- Before any UI or visual decision, read `doc/DESIGN.md`.
- Do not deviate from the Neo-Brutalist Zine design system (3px solid black borders, flat drop shadows, pop art color blocks, and Syne/Outfit/Space Grotesk typography) without explicit approval.
- UI QA must call out any mismatch with `doc/DESIGN.md`.

## NOTES

- Local launcher uses backend `8000`, frontend `3000`, worker `python -m app.workers.crawler --kind all`.
- Runtime config: `ALLOWED_ORIGINS` controls CORS origins (comma-separated or JSON list), `CRAWLER_HEADLESS=false` opens Playwright/profile browsers visibly for local debugging, and `PRODUCT_CRAWL_CONCURRENCY` bounds product fan-out inside one worker task (default/minimum `1`).
- `frontend/playwright.config.ts` defaults to `http://localhost:5173`; set `E2E_BASE_URL=http://localhost:3000` for this repo's launcher.
- Boss runtime JSONL logs live under `backend/logs/boss_cloak_adapter_<timestamp>.jsonl` and are gitignored.
- GitNexus full-text index warning may appear; run `npx gitnexus analyze --force` if keyword search is degraded.
- Smart home config lives under `/v1/smart-home/*`; do not store Home Assistant tokens without a real `SMART_HOME_SECRET_KEY`.
