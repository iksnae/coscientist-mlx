# Milestone 13 Tracking

Date: 2026-06-05

Milestone:

```txt
iOS polish — iPad layout + on-device hardening
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | TBD |
| Actual end | TBD |
| Elapsed | TBD |
| Scope class | Small-to-Medium |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Memory-guard + thermal-action decisions are pure and unit-tested with fed-in signals. | Pending | Track A |
| iOS applies the pre-run memory check (warn, not doomed run) and stops cleanly on critical thermal. | Pending | Track A |
| iPad/regular renders the inspector as a trailing pane; iPhone/compact stacks. | Pending | Track B |
| No regression to the iPhone flow or the macOS app (both build). | Pending | Track B |
| New decision logic is test-first (mock, no GPU). | Pending | all tracks |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Pending | `git grep` check |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Pending | — |
| `swift test` | Pending | — |
| macOS app build | Pending | — |
| iOS app build (simulator) | Pending | — |
| `git diff --check` | Pending | — |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Critical thermal → stop-with-partial-results. | Accepted | Reuses the existing cancel path; simpler than pause/resume. |
| Memory check reuses `minRAMGB`/`approxSizeGB`. | Accepted | Consistent with the `DownloadGuard` disk check. |
| Hardening decisions live as pure logic in Kit. | Accepted | Device signals are fed in; logic stays unit-testable. |
