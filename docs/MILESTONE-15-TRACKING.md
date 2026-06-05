# Milestone 15 Tracking

Date: 2026-06-05

Milestone:

```txt
iOS — redesigned UX + iPad layout + on-device hardening
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | TBD |
| Elapsed | TBD |
| Scope class | Medium |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Memory-guard + thermal-action decisions are pure + unit-tested with fed-in signals. | Pending | Track A |
| iOS applies a GPU cache cap; a low-memory pre-run check warns/blocks; critical thermal stops cleanly with a recorded reason. | Pending | Track A |
| iPad/regular renders Studies + detail + inspector as columns (inspector a trailing pane); iPhone/compact stacks. | Pending | Track B |
| The M13/M14 flow (model selection, picker, Advanced config, results outcome) works on iOS; no regression to iPhone or macOS. | Pending | Track C |
| New decision logic is test-first (mock, no GPU). | Pending | all tracks |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Pending | `git grep` check |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Pending | — |
| `swift test` | Pending | — |
| macOS app build | Pending | — |
| iOS app build | Pending | — |
| `git diff --check` | Pending | — |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Critical thermal → stop-with-partial-results. | Accepted | Reuses the existing cancel path; simpler than pause/resume. |
| Memory-fit check reuses `minRAMGB`. | Accepted | Consistent with the M13 picker's compatibility check. |
| Hardening decisions live as pure Kit logic; device signals fed in. | Accepted | Keeps it unit-testable without a device. |
