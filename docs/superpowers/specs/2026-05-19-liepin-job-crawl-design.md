# Liepin Job Crawl Design

Date: 2026-05-19

## Goal

Add Liepin (`https://www.liepin.com/`) as a long-running, stable job crawling
platform in the existing multi-platform job system.

The implementation should support:

- Creating and running `liepin` job search configs.
- Prefer lightweight backend HTTP requests when Liepin returns usable JSON.
- Automatically fall back to a real browser CDP flow when HTTP is blocked,
  challenged, redirected to login, or returns invalid data.
- Reusing an already logged-in browser session when available, without making
  login a hard requirement for public results.
- Persisting search results and filling job details.
- Making failures visible and actionable in crawl logs/events.
- Closing any temporary browser tabs created by the crawler.

## Existing Context

The repository already has a shared job crawling pipeline:

- `JobSearchConfig.platform` selects the platform adapter.
- `crawl_single_config()` creates the adapter and calls `adapter.crawl(url)`.
- `process_job_results()` handles deduplication, insert/update, notifications,
  crawl logs, and detail enrichment.
- Boss and 51job already share this pipeline.
- 51job uses a CDP-backed browser fetch path for WAF-sensitive search APIs.

Liepin should follow this existing adapter pattern rather than introduce a new
parallel service.

## Platform Surface

Add `liepin` as a first-class job platform key.

Required platform propagation:

- Backend schema: `JobPlatform = Literal["boss", "51job", "liepin"]`.
- Database constraint for `job_search_configs.platform`.
- Backend platform normalizer and adapter factory.
- Notification platform label: `猎聘`.
- Frontend types for job configs and jobs.
- Frontend platform display tag in the job list/config surfaces.

No new standalone UI page is required. The existing Job Management UI remains
the entry point.

## Adapter Design

Add `LiepinAdapter` under `backend/app/platforms/`.

### Search Flow

The adapter should use a two-path search strategy:

```text
crawl(url)
→ parse keyword/city/page params from config.url
→ try curl_cffi search API request
→ validate response as real job JSON
→ if valid: transform_jobs()
→ if invalid: open temporary Liepin CDP tab
→ execute browser fetch for the search API
→ validate response as real job JSON
→ transform_jobs()
→ close temporary tab in finally
```

HTTP should be considered failed when any of these are true:

- Non-200 status.
- Response is HTML instead of JSON.
- Response contains login, verification, CAPTCHA, or security challenge markers.
- JSON shape lacks the expected job list.
- Job list is unexpectedly empty while the query should have results.

CDP fallback should:

- Use the existing local browser remote debugging endpoint.
- Open a temporary `liepin.com` search tab.
- Execute fetch inside that browser context.
- Reuse any existing login/session state naturally through the browser profile.
- Close only the temporary tab created by this crawl.
- Return a clear error if the CDP browser is unavailable.

### Search Transformation

Transform Liepin search JSON into the existing normalized job dict shape:

- `job_id`
- `title`
- `company`
- `company_id`
- `salary`
- `location`
- `experience`
- `education`
- `url`
- optional `description`
- optional `address`

The normalized output should be compatible with `process_job_results()`.

## Detail Enrichment

Liepin should support search results plus detail completion.

Detail rules:

- New jobs should be detail-enriched.
- Existing jobs should be detail-enriched when `description` or `address` is
  missing.
- Existing jobs with complete detail should not be refreshed every crawl.

This requires a small platform-neutral extension to `process_job_results()`:

- Track newly inserted jobs for detail enrichment.
- Track existing updated jobs whose detail fields are still missing.
- Pass both groups into the existing detail update loop.
- Keep the detail loop rate-limited and sequential.

`LiepinAdapter.crawl_detail(job_id)` should:

- Prefer a backend HTTP request to a detail API or detail page when possible.
- Validate that the response is real detail content.
- Fall back to CDP when HTTP is challenged, redirected, or missing data.
- Extract `description` and `address`.
- Return structured success/error results consistent with existing adapters.

Detail failures should not roll back successful search-result persistence.

## Error Handling

Search failure is a crawl failure.

Detail failure is not a crawl failure if search results were already saved.
Instead:

- Count detail errors.
- Log the number of failed detail enrichments.
- Stop detail enrichment after 3 consecutive detail failures.
- Keep the crawl log `SUCCESS` when search persistence succeeded.

User-facing errors should distinguish:

- CDP browser not running.
- Liepin verification/CAPTCHA required.
- Login required or session unavailable.
- Search API response shape changed.
- Detail response shape changed.

## Scheduling

Liepin configs should work with the existing per-config job scheduler.

No scheduler-specific platform logic is required beyond ensuring:

- `platform=liepin` configs can be saved.
- `crawl_single_config()` can route to `LiepinAdapter`.
- scheduled runs use the same search and detail behavior as manual runs.

## Testing

### Contract Tests

- `JobPlatform` accepts `liepin`.
- Create/update job config supports `platform=liepin`.
- Job responses can serialize `platform=liepin`.
- Notifications use the `猎聘` platform label.
- Frontend types and platform display support `liepin`.

### Adapter Tests

- HTTP search JSON success path uses the HTTP response.
- HTTP HTML/challenge response falls back to CDP.
- CDP temporary tab is created and closed.
- CDP unavailable returns a clear error.
- Search JSON maps to normalized job dicts.
- Detail HTTP success extracts description/address.
- Detail HTTP challenge falls back to CDP.
- Detail CDP failure returns structured error.

### Pipeline Tests

- New Liepin jobs are inserted.
- New jobs enter detail enrichment.
- Existing jobs with missing detail enter detail enrichment.
- Existing jobs with complete detail skip detail enrichment.
- Three consecutive detail failures stop further detail work.
- Detail failure does not roll back saved search results.

### Real E2E Verification

Use a retained test config such as `codex-e2e-liepin-kept-<time>`.
Do not delete retained E2E configs unless the user explicitly asks for cleanup.

Verification steps:

1. Probe the Liepin search endpoint with `curl_cffi`.
2. If direct HTTP fails, probe the same request via CDP browser fetch.
3. Create a Liepin job config.
4. Trigger `/jobs/crawl-now/{id}`.
5. Wait for task completion.
6. Confirm latest crawl log is `SUCCESS`.
7. Confirm Liepin jobs are persisted.
8. Confirm at least one job has detail fields populated.
9. Confirm temporary Liepin tabs are closed.

## Out of Scope

- Automated Liepin account login.
- CAPTCHA solving.
- A new dedicated Liepin UI page.
- Full refresh of every existing job detail on every crawl.
- Reworking Boss or 51job search strategies.

## Open Implementation Notes

Before implementation, inspect Liepin DevTools traffic to identify the current
search and detail endpoints, request headers, and JSON response shape. If the
endpoint shape changes during implementation, keep the adapter parser isolated
so future updates are localized to `LiepinAdapter`.
