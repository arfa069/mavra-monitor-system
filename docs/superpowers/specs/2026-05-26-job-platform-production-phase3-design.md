# Phase 3: Job Platform Productionization Design

Date: 2026-05-26

## Goal

Phase 3 turns the three job crawlers into production-usable platform integrations on top of the Phase 2 persistent task and Profile Pool foundation.

The target behavior is:

- A job search config can choose a `profile_key`.
- One profile can store login state for multiple platforms, but at one moment it can only be leased by one crawl task.
- Full job crawl runs in parallel by `(platform, profile_key)`, while configs sharing the same tuple run serially.
- Boss, 51job, and Liepin expose consistent crawl logs, failure categories, Event Center records, and profile state transitions.
- Liepin becomes HTTP-only for normal execution.
- 51job keeps the current CloakBrowser-based production path, while HTTP-only remains an instrumented experiment.

## Non-Goals

This phase does not introduce an independent worker process. FastAPI/APScheduler still create and execute tasks in-process, using the Phase 2 persistent task records.

This phase does not productize commodity crawler profiles. Product crawlers still keep their existing behavior until the product crawler phase.

This phase does not delete or rename profile directories. Browser profile folders contain login state and should not be destructively managed from the first version of the UI.

This phase does not make 51job HTTP-only the default path.

## Data Model

### `jobs_search_configs.profile_key`

Add a nullable or defaulted `profile_key` column to `jobs_search_configs`.

Rules:

- New configs default to `default`.
- Existing configs are backfilled to `default`.
- Values are validated with the existing profile path segment rules: no slash, backslash, empty value, `.` segment, or `..` segment.
- The value is stored on job config create/update responses so the frontend can display and edit it.

### `crawl_profiles`

The Phase 2 `crawl_profiles` table remains the source of truth for profile lease state.

Phase 3 adds API behavior around the existing fields rather than replacing the table:

- `profile_key`
- `profile_dir`
- `status`
- `platform_hint`
- `lease_owner`
- `lease_task_id`
- `lease_until`
- `last_used_at`
- `last_error`

Allowed statuses remain:

- `available`
- `leased`
- `login_required`
- `cooling_down`
- `disabled`

`leased`, `login_required`, `cooling_down`, and `disabled` block new leases unless the operation is an explicit safe maintenance action.

## API Design

### Job Config API

Extend existing job config create/update/list/detail endpoints with `profile_key`.

Behavior:

- Create: if `profile_key` is missing or blank, store `default`.
- Create/update: if `profile_key` is provided, validate it and require an existing `crawl_profiles` row.
- Read: include `profile_key` in `JobSearchConfigResponse`.
- Scheduled/manual crawl: use the config's `profile_key` instead of hardcoded `default`.

### Profile Management API

Add profile management endpoints under the existing API prefix.

Proposed endpoints:

- `GET /v1/crawl-profiles`
- `POST /v1/crawl-profiles`
- `PATCH /v1/crawl-profiles/{profile_key}`
- `POST /v1/crawl-profiles/{profile_key}/release-stale`

Supported operations:

- List profile status and lease metadata.
- Create a profile record and ensure `/profiles/{profile_key}` exists.
- Enable or disable a profile.
- Mark a profile as `available` or `login_required`.
- Release a stale or stuck lease when the task is no longer running or the lease has expired.

Not supported:

- Delete profile record.
- Delete profile directory.
- Rename profile key.
- Edit `profile_dir` directly from UI.
- Dump cookies, local storage, or browser profile contents through API.

## Frontend Design

Add profile controls with minimal UI expansion.

### Job Config Form

Add a `profile_key` field to the existing job config form.

Preferred UI:

- Use a Select populated from `GET /v1/crawl-profiles`.
- Do not allow arbitrary free-form profile keys in the config form.
- New profile keys are created explicitly in the `Profiles` tab before they are assigned to configs.
- Default selection is `default`.

The config list should show `profile_key` so operators can see why two configs can or cannot run concurrently.

### Profile Management View

Add a Jobs module tab, for example `Profiles`, instead of creating a new top-level product area in this phase.

The table shows:

- Profile key
- Status
- Platform hint
- Lease task id
- Lease owner
- Lease until
- Last used at
- Last error
- Read-only profile path

Actions:

- Create profile
- Disable
- Enable or mark available
- Mark login required
- Release stale lease

Destructive actions are deliberately absent.

## Execution Flow

### Single Config Crawl

1. Load `JobSearchConfig`.
2. Resolve `platform` and `profile_key`.
3. Acquire `DatabaseProfilePool.lease(platform, profile_key, owner, task_id)`.
4. Pass the lease's `profile_dir`, `profile_key`, and task context into the adapter.
5. Start heartbeat renewal.
6. Run the crawler.
7. Persist task status, Event Center records, JSONL logs, and profile status changes.
8. Stop heartbeat and release the lease.

### Scheduled Config Crawl

Scheduled config crawl uses the same path as manual single config crawl.

The task payload and `crawl_tasks.profile_key` must record the actual config profile key, not `default` unless that is the config value.

### Full Job Crawl

Current full crawl groups by platform. Phase 3 changes this to group by `(platform, profile_key)`.

Rules:

- Same platform + same profile: serial.
- Same platform + different profiles: parallel.
- Different platform + different profiles: parallel.
- Different platform + same profile: serial because the same browser profile cannot be opened by two tasks at once.

Implementation shape:

- Parent task: `job_all`.
- Child task: one `job_platform_profile` task per `(platform, profile_key)` group.
- Each child owns exactly one profile lease.
- Parent aggregates child totals, successes, errors, and details.

If a profile is unavailable, only that child group fails. Other groups can continue.

## Adapter Runtime Contract

Add a small runtime context passed from crawl service to adapters.

Minimum fields:

- `profile_key`
- `profile_dir`
- `task_id`
- `config_id`
- `platform`
- `run_id`
- `log_context`

The adapter factory should accept this context or explicit keyword arguments. Adapters must not silently fall back to `build_profile_dir("default")` when a lease is already held.

This prevents a serious production bug where the DB leases one profile but the browser opens a different directory.

## Platform Behavior

### Boss

Boss continues using the current hybrid approach:

- CloakBrowser profile for login/cookie refresh.
- HTTP/curl-cffi for list and detail requests.

Phase 3 changes:

- Inject `profile_dir` from the active lease.
- Classify anti-bot response codes `36`, `37`, and `38`.
- Emit structured JSONL events for anti-bot hits, cookie refresh attempts, refresh success, refresh failure, and crawl finish.
- After repeated refresh failures, mark the profile `login_required`, fail the task quickly, and emit an Event Center warning.

One transient anti-bot response should not permanently mark a profile as bad. The transition to `login_required` requires repeated failure in the same run or a clear login-required response.

### 51job

51job keeps the current production path:

- Open CloakBrowser persistent profile.
- Execute search API inside browser context.
- Avoid address/detail supplementation unless a later phase explicitly reintroduces it.

Phase 3 changes:

- Inject `profile_dir` from the active lease.
- Add JSONL logs aligned with Boss and Liepin.
- Log at least `crawl_start`, `list_page`, `waf`, `empty_result`, `crawl_finish`, and `crawl_failed`.
- Add WAF fuse behavior. After repeated WAF/challenge pages, stop quickly instead of idling through all pages.
- Emit Event Center records for WAF fuse and login-required/profile-required states.

HTTP-only experiment:

- Add a diagnostic path that does not write jobs.
- Report success rate, elapsed time, WAF hit rate, empty result rate, and representative failure category.
- Do not switch normal production crawl to HTTP-only in Phase 3.

### Liepin

Liepin becomes HTTP-only.

Phase 3 changes:

- Remove normal CDP fallback behavior.
- Do not open browser tabs during standard crawl or detail fetch.
- Classify HTTP failures:
  - XSRF/session failure
  - challenge/login response
  - empty result
  - list HTTP error
  - list parse error
  - detail HTTP error
  - detail parse failure
- Add JSONL logs aligned with Boss and 51job.

If HTTP detail parsing fails for some jobs, the config can still partially succeed if list crawl succeeded and enough jobs were processed. The result should surface detail failure counts instead of hiding them as a generic crawl failure.

## Logging and Event Center

### JSONL Logs

Each platform should write JSONL records with a common envelope:

- timestamp
- platform
- profile_key
- task_id
- config_id
- event
- status
- elapsed_ms where relevant
- page where relevant
- count fields where relevant
- failure_category where relevant
- message

Platform-specific fields are allowed, but the common envelope makes production triage consistent.

### Event Center

Event Center must receive records for:

- job crawl started
- job crawl completed
- job crawl failed
- profile marked login required
- profile disabled/enabled by operator
- profile lease unavailable
- WAF/challenge fuse tripped
- stale lease manually released

Events should include `task_id`, `config_id` when available, `platform`, `profile_key`, and `failure_category`.

## Failure Taxonomy

Use a shared set of failure categories for job crawling:

- `profile_unavailable`
- `profile_leased`
- `profile_login_required`
- `anti_bot`
- `waf`
- `challenge`
- `xsrf`
- `empty_result`
- `http_error`
- `parse_error`
- `detail_error`
- `cookie_refresh_failed`
- `timeout`
- `unknown`

Adapters can map native platform errors into this taxonomy.

Task responses and logs should preserve the human-readable message, but programmatic decisions should use `failure_category`.

## Security

Profile directories stay under `/price-monitor/profiles/{profile_key}`.

Security rules:

- Validate `profile_key` before building a path.
- Never accept arbitrary profile paths from API requests.
- Do not expose cookies, local storage, or profile file contents in API responses.
- Do not store cookie JSON files as the normal production login-state mechanism.
- Use profile directory state as local runtime data and keep it out of git.
- Maintenance actions must require the same permission level as existing crawler/job configuration operations.

## Backward Compatibility and Migration

Migration steps:

1. Add `profile_key` column to `jobs_search_configs`.
2. Backfill existing rows to `default`.
3. Ensure a `crawl_profiles` row exists for `default`.
4. Preserve existing job configs and schedules.

After migration, old configs behave the same because they still use the `default` profile.

## Testing Plan

### Unit and Integration Tests

Cover:

- `profile_key` validation.
- Job config create/update/read includes profile key.
- Single config crawl leases the config profile key.
- Scheduled crawl leases the config profile key.
- Full crawl groups by `(platform, profile_key)`.
- Same profile groups do not run concurrently.
- Different profile groups can run concurrently.
- Adapter factory passes lease `profile_dir`.
- Profile management API blocks invalid keys and destructive path traversal.
- Profile status transitions block or allow leasing correctly.
- Liepin does not call CDP helpers.
- 51job WAF fuse stops early.
- Boss anti-bot code mapping produces the expected failure category.

### Real Environment E2E

Run real front/back integration after implementation:

1. Create at least two profiles, for example `job-a` and `job-b`.
2. Create two Boss configs with different profile keys.
3. Run full job crawl and verify both groups can run concurrently.
4. Create configs sharing one profile and verify they serialize.
5. Verify Event Center records crawl start/completion/failure and profile events.
6. Verify JSONL logs exist for Boss, 51job, and Liepin.
7. Verify Liepin normal crawl does not open CDP tabs.
8. Verify 51job WAF fuse fails fast when WAF is encountered repeatedly.

## Edge Cases

- Config create/update references a missing profile: reject the request with a validation error.
- Existing config references a missing profile because of manual DB edits or partial migration: task fails fast with `profile_unavailable`.
- Config references disabled profile: task fails fast with `profile_unavailable`.
- Profile is `login_required`: task fails fast and Event Center records the reason.
- Lease heartbeat stops but process continues: stale lease recovery should be able to release expired leases.
- Parent full crawl is cancelled or crashes: child tasks may leave leases until heartbeat expiry; recovery handles cleanup.
- One child group fails in full crawl: parent records partial failure and keeps successful child results.
- Operator releases a lease while a task is still actively heartbeating: API should reject unless the lease is expired or the task is no longer active.
- Adapter reports empty result: classify separately from WAF/challenge so real zero-result searches are not treated as login failures.

## Rollout

Recommended rollout order:

1. Add data model/API/schema support for `profile_key`.
2. Add Profile Management API and basic UI.
3. Inject lease profile context into job crawl execution.
4. Change full crawl grouping to `(platform, profile_key)`.
5. Add shared failure taxonomy and Event Center payload fields.
6. Update Boss.
7. Update 51job production path and HTTP-only experiment.
8. Update Liepin to HTTP-only.
9. Run unit, integration, and real environment E2E tests.

This order keeps the profile foundation observable before platform-specific behavior starts depending on it.
