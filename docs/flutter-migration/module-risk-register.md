# Flutter Migration Module Risk Register

| Module | Risk | Severity | Mitigation | Owner during execution | Gate |
| --- | --- | --- | --- | --- | --- |
| Auth | Cookie/CSRF to token-first changes security boundaries | Critical | TDD, security decision record, Web/native storage split, replay tests | backend auth task | A |
| WeChat | Browser hash callback does not fit mobile or Windows | High | one-time exchange code, platform callbacks, deterministic fake store tests | auth/WeChat task | A |
| API generation | Generated Dart output may drift by tool version | High | pin wrapper and generator, clean/check modes, CI diff check | codegen task | B |
| Big-bang cutover | React runtime disappears before feature parity | Critical | immutable React commit, parity checklist, task commits, explicit Task 7 owner gate | integration owner | B-F |
| Jobs | Uploads, backup, matching, profiles and crawl operations are coupled | Critical | dedicated repositories, mock-only automation, accepted-scope gate | jobs task | D |
| Blog | Tiptap does not port directly to Flutter | High | approve Markdown or structured editor before implementation | blog task | E |
| Smart Home | Tests could operate real devices or expose HA token | Critical | fake HA client, redaction, no live service calls | smart-home task | E |
| Realtime | SSE support and auth differ by platform | High | transport abstraction with polling fallback and disconnect state | platform task | A-C |
| Windows | Secure storage, URI registration, installer and file dialogs differ | High | early capability spike, Windows smoke, signed MSIX plan | platform task | B-C |
| Android | SDK/emulator environment is still being installed | High | finish SDK, licenses, AVD and real build before Gate B/C | platform owner | B-C |
| iOS | No local macOS environment | High | required macOS CI build and simulator evidence | release owner | C-F |
| Web auth | XSS may expose in-memory access token; cookie refresh adds CSRF boundary | Critical | short access lifetime, HttpOnly refresh, Origin/Referer validation | backend/core task | A |
| File operations | Browser, mobile and Windows picker/download APIs differ | High | `core/files` abstraction and per-platform smoke tests | platform task | C-D |
| Dense management UI | Mobile layouts may become unusable copies of desktop tables | Medium | approved mobile reductions and design references | design/feature tasks | C-E |
| Accessibility | Custom Flutter widgets may lose browser/desktop semantics | High | semantics, focus, text-scale and touch-target tests | shared UI task | C-F |
| API path ownership | Dart code may reintroduce `/v1` or duplicate `/api/v1` | High | generated clients, single AppConfig owner, grep/checker gate | codegen/core task | B-F |

## Stop Conditions

Stop execution and report before proceeding when:

- GitNexus reports HIGH or CRITICAL impact that is broader than the assigned
  task.
- Token replay, cookie origin validation, or session revocation tests cannot be
  made deterministic.
- Task 7 cannot preserve `frontend/openapi.json` and an immutable React
  reference.
- Generated Dart output is not reproducible.
- A platform requires plaintext token persistence.
- Automated tests require a real crawl, profile login, matching run, or Home
  Assistant service call.

## Review Cadence

- Update this register at Gates A-F.
- Add the owning task and evidence link when a mitigation is complete.
- Do not delete closed risks; mark them mitigated with the commit and
  verification command.
