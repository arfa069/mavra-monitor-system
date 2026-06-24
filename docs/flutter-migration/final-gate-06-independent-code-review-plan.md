# Final Gate 06: Independent Code Review Plan

> **For agentic workers:** this gate must be a separate review pass from verification. Review findings lead the report; summaries come after issues.

## Goal

Complete an independent final code-review pass for the Flutter migration diff from the React cutover baseline through `b4af331d`. The review decides whether the branch is safe to enter final merge preparation.

## Review Scope

Use the React cutover baseline recorded in the migration history and compare it to `b4af331d`.

```powershell
cd C:/Users/arfac/Documents/mavra-monitor-system
git diff --stat <react-cutover-baseline>..b4af331d
git diff --name-only <react-cutover-baseline>..b4af331d
```

If the exact baseline hash is already recorded in `docs/flutter-migration/final-verification-report.md`, use that hash and quote it in the review report.

## Review Focus Areas

- API usage: generated clients, `/api/v1` ownership, no new hand-written JSON Axios paths.
- Auth: cookie/token handling, CSRF behavior, logout behavior, and secure storage by platform.
- Route parity: React routes versus Flutter routes, protected-route behavior, fallback routes, browser refresh.
- Platform adapters: Web, Windows, Android emulator, and deferred iOS behavior.
- File picking, downloads, browser launch, clipboard, notifications, and other platform capability checks.
- Dependency hygiene: unused packages, platform-specific packages, generated files, lockfile drift.
- CI and docs drift: commands in docs match actual Flutter and backend commands.
- Test coverage: unit, widget, integration smoke, backend contract, and platform verification evidence.
- Release blockers: known failing tests, manual QA gaps, signing/package gaps, security concerns.

## Review Method

1. Read the migration verification docs first.

   ```powershell
   Get-Content -Raw docs/flutter-migration/final-verification-report.md
   Get-Content -Raw docs/flutter-migration/platform-verification-matrix.md
   Get-Content -Raw docs/flutter-migration/react-parity-checklist.md
   ```

2. Inspect high-risk file groups from the diff.

   ```powershell
   git diff --name-only <react-cutover-baseline>..b4af331d -- frontend
   git diff --name-only <react-cutover-baseline>..b4af331d -- .github docs doc
   git diff --name-only <react-cutover-baseline>..b4af331d -- backend
   ```

3. Review code paths by risk, not by file order.

   Start with auth, API transport, route guards, platform adapters, build configuration, and test harnesses.

4. Produce a review report.

   Suggested output path:

   ```text
   docs/flutter-migration/final-code-review-report.md
   ```

## Findings Format

Findings must lead the report and use this shape:

```text
Severity: Critical | High | Medium | Low
File:
Line:
Issue:
Impact:
Recommended fix:
```

If no issues are found, state that clearly and list residual risk separately.

## Acceptance Criteria

- Review is performed in a separate pass from command verification.
- All findings have severity, file, line or narrow location, impact, and recommended fix.
- Critical and high findings are fixed or explicitly rejected with owner rationale before merge preparation.
- The review report states one of: allow final merge preparation, allow after listed fixes, or block merge preparation.
- The final verification report links to the independent review report.

## Evidence To Record

Update both files after this gate runs:

- `docs/flutter-migration/final-verification-report.md`
- `docs/flutter-migration/platform-verification-matrix.md`

Record:

- Baseline hash used.
- Reviewed diff range.
- Reviewer identity or review mechanism.
- Findings count by severity.
- Final merge-readiness decision.
