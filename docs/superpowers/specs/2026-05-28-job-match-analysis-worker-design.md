# Job Match Analysis Worker Design

Date: 2026-05-28

## Goal

Move job match analysis from the in-memory `task_registry` background path into the durable `crawl_tasks` and crawler worker system.

The target behavior is:

- Manual match analysis is persisted as `crawl_tasks`.
- Crawl-triggered automatic match analysis is persisted as `crawl_tasks`.
- A dedicated `analysis` worker executes match analysis tasks.
- FastAPI does not run LLM match analysis directly in normal operation.
- The existing frontend polling path remains compatible.

## Non-Goals

- Do not redesign the resume or match result schema.
- Do not remove `match_score` from the database or API response in this phase.
- Do not change the current recommendation labels: `强烈推荐`, `可以考虑`, `不太匹配`.
- Do not move match analysis into product/job crawl profile leases. Match analysis does not need browser profiles.
- Do not add multi-task concurrency inside one analysis worker. One worker executes one task at a time.

## Decisions

- Add task type `job_match_analysis`.
- Add worker kind `analysis`.
- One `job_match_analysis` task analyzes one resume against one list of job IDs.
- If crawl-triggered auto-analysis needs to analyze multiple resumes, create one task per resume.
- Keep `GET /v1/jobs/tasks/{task_id}` as the frontend polling API, but read from `crawl_tasks`.
- Change both `POST /v1/jobs/match-results/analyze-async` and `POST /v1/jobs/match-results/analyze` to enqueue durable tasks instead of executing LLM analysis inline.
- Keep `all_up_to_date` behavior: if no jobs need analysis, return completed without creating a task.

## Data Model

Use existing `crawl_tasks`.

`job_match_analysis` records:

- `task_type`: `job_match_analysis`
- `source`: `manual`, `crawl_auto`, or another existing source string
- `user_id`: requesting user ID
- `entity_type`: `resume`
- `entity_id`: resume ID as string
- `total`: number of jobs that need analysis
- `success`: successful job analyses
- `errors`: failed or skipped item count
- `payload_json`:

```json
{
  "resume_id": 123,
  "job_ids": [1, 2, 3]
}
```

`details_json` may store a compact summary after execution:

```json
[
  {
    "resume_id": 123,
    "processed": 3,
    "created": 2,
    "updated": 1,
    "skipped": 0
  }
]
```

Do not store full resume text or prompt content in `payload_json` or `details_json`.

## API Design

### `POST /v1/jobs/match-results/analyze-async`

Behavior:

1. Validate the current user.
2. Validate `resume_id` belongs to the current user.
3. Resolve target `job_ids`.
4. Filter to jobs that need analysis.
5. If no jobs need analysis, return:

```json
{
  "status": "completed",
  "task_id": null,
  "total": 0,
  "reason": "all_up_to_date"
}
```

6. Otherwise create a `job_match_analysis` `crawl_tasks` row and return:

```json
{
  "status": "pending",
  "task_id": "abc",
  "total": 10
}
```

### `POST /v1/jobs/match-results/analyze`

This path becomes an enqueue alias for the async behavior. It keeps the route path, but it no longer waits for LLM completion.

The response shape should match the async enqueue response. This is an intentional behavior change so production API processes do not execute match analysis inline.

### `GET /v1/jobs/tasks/{task_id}`

Keep the path for frontend compatibility.

Read from `crawl_tasks` and return:

```json
{
  "task_id": "abc",
  "status": "pending|running|completed|failed",
  "total": 10,
  "success": 4,
  "errors": 0,
  "reason": null,
  "worker_id": "worker:...",
  "heartbeat_at": "2026-05-28T...",
  "lease_until": "2026-05-28T..."
}
```

When completed, frontend refetches `GET /v1/jobs/match-results` to show final rows. The task status API does not need to embed full match result records.

## Worker Design

### Task Claiming

Extend task type grouping:

- `ANALYSIS_TASK_TYPES = {"job_match_analysis"}`
- `task_types_for_kinds({"analysis"})` returns `job_match_analysis`.
- `task_types_for_kinds({"job"})` does not return `job_match_analysis`.
- `task_types_for_kinds({"all"})` returns analysis, job, and product task types.

Extend worker CLI:

```bash
python -m app.workers.crawler --kind analysis
```

`--kind analysis` does not need platform filtering.

### Task Execution

`executor.py` adds dispatch for `job_match_analysis`.

Execution steps:

1. Convert the `crawl_tasks` record to a runtime `CrawlTask`.
2. Read `resume_id` and `job_ids` from `payload_json`.
3. Validate the resume still exists and belongs to `record.user_id`.
4. Run existing match analysis logic against those jobs.
5. Persist progress through the existing worker `progress_callback`.
6. Mark the task completed or failed.

Match execution should use `record.user_id`; do not keep the current `user_id == 1` assumption in the worker path.

The task remains single-task-per-worker. Inside one task, use the current match analysis batch size of 3 for LLM calls.

## Automatic Analysis After Crawling

In `process_job_results()`:

- If `new_job_ids` is empty, do nothing.
- If `enable_match_analysis` is false, do nothing.
- If enabled, query all resumes for `config.user_id`.
- Create one `job_match_analysis` task per resume.
- Do not await LLM analysis in the crawl worker.

This keeps job crawling independent from LLM throughput and avoids blocking profile/browser resources while analysis runs.

## Error Handling

### No Work

If all target jobs are already up to date, do not create a task. Return `completed`, `task_id=null`, and `reason=all_up_to_date`.

### Resume Missing

If the resume is missing at API time, return 404.

If the resume is deleted after enqueue and before worker execution:

- Mark task `failed`.
- Set `reason=resume_not_found`.

### Item Failures

If an individual LLM call fails:

- Increment `errors`.
- Continue with remaining jobs.

If at least one job succeeds, the task can finish as `completed` with non-zero `errors`.

If every attempted item fails, mark task `failed` with `reason=all_items_failed`.

### Worker Crash

Reuse Phase 5 stale running task recovery:

- Expired running analysis tasks become `failed`.
- Do not automatically requeue in the first version, to avoid duplicate LLM calls and duplicate notifications.

### Notification Failure

Feishu notification failure does not fail the task.

Notify only for:

- `强烈推荐`
- `可以考虑`

Do not notify for:

- `不太匹配`

## Event Center

Emit a dedicated enqueue event:

- `job_match_analysis.enqueued`

Use existing worker events for execution:

- `crawler_worker.task_claimed`
- `crawler_worker.task_completed`
- `crawler_worker.task_failed`

Payloads must include:

- `task_id`
- `resume_id`
- `job_count`
- `source`

Payloads must not include resume text, prompts, tokens, or provider credentials.

## Frontend Design

The Match Results UI keeps the current user flow:

1. Select resume.
2. Click `Re-analyze`.
3. Receive `task_id`.
4. Poll `GET /v1/jobs/tasks/{task_id}`.
5. Show `success/total`.
6. Refetch match results on completion.

If no analysis worker is running:

- Task remains `pending`.
- UI should not crash.
- Existing polling can continue until terminal state.

The recommendation filter remains based on:

- `强烈推荐`
- `可以考虑`
- `不太匹配`

## Testing

### Backend

- `task_types_for_kinds({"analysis"})` includes `job_match_analysis`.
- `task_types_for_kinds({"job"})` excludes `job_match_analysis`.
- `task_types_for_kinds({"all"})` includes `job_match_analysis`.
- `POST /jobs/match-results/analyze-async` creates a `crawl_tasks` record.
- `POST /jobs/match-results/analyze` creates a `crawl_tasks` record and does not call the LLM provider inline.
- `all_up_to_date` returns completed without creating a task.
- `execute_claimed_task()` dispatches `job_match_analysis`.
- Worker updates `total`, `success`, `errors`, `status`, `reason`, and `details_json`.
- Deleted resume during execution marks the task failed.
- All item failures mark the task failed.
- Crawl-triggered auto-analysis creates one task per resume and does not wait for worker completion.

### Frontend

- `npm run lint`
- `npm run build`
- Browser verification:
  - Trigger Match Results `Re-analyze`.
  - Confirm a durable task ID is returned.
  - Confirm polling uses `GET /v1/jobs/tasks/{task_id}`.
  - Confirm Event Center shows enqueue and worker execution events after an analysis worker runs.

## Rollout

1. Add task type and worker kind.
2. Add enqueue helper for match analysis.
3. Convert manual analysis endpoints to enqueue.
4. Convert crawl-triggered automatic analysis to enqueue.
5. Add worker executor dispatch.
6. Update status endpoint to read `crawl_tasks`.
7. Update frontend types only where response shape requires it.
8. Run backend targeted tests, frontend lint/build, and one real frontend/backend worker validation.

## Acceptance Criteria

- No LLM match analysis runs inside FastAPI request handling.
- No LLM match analysis runs inside job crawl execution.
- Manual and automatic match analysis tasks are visible in `crawl_tasks`.
- `analysis` worker can claim and complete `job_match_analysis` tasks.
- Existing Match Results page still shows progress and refetches results on completion.
- Event Center shows enqueue and worker lifecycle events.
