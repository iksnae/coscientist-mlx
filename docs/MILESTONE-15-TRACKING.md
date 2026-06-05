# Milestone 15 Tracking

Date: 2026-06-05

Milestone:

```txt
iOS — redesigned UX + iPad layout + on-device hardening
```

## Status

Complete

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | 2026-06-05 |
| Elapsed | same day |
| Scope class | Medium |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Memory-guard + thermal-action decisions are pure + unit-tested with fed-in signals. | Done | `RunGuardTests` (78309e3) |
| iOS applies a GPU cache cap; a low-memory pre-run check warns/blocks; critical thermal stops cleanly with a recorded reason. | Done | `WorkflowRunner` `#if os(iOS)` GPU cap + memory block + thermal→cancel in `apply` (e38ced8) |
| iPad/regular renders the inspector as a trailing pane; iPhone/compact uses a sheet. | Done | `StudyDetailView.inspectorSplit` size-class adaptive (e38ced8) |
| The M13/M14 flow works on iOS; no regression to iPhone or macOS. | Done | macOS + iOS BUILD SUCCEEDED (shared views carry M13/M14). |
| New decision logic is test-first (mock, no GPU). | Done | `RunGuardTests` written before impl. |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Done | `git grep` → only `Package.swift` comment. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on Apple Silicon. |
| `swift test` | Passed | 148 tests / 35 suites green (+2). |
| macOS app build | Passed | `xcodebuild … CoScientistDemo` BUILD SUCCEEDED. |
| iOS app build | Passed | `xcodebuild … CoScientistApp` BUILD SUCCEEDED. |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Critical thermal → stop-with-partial-results. | Accepted | Reuses the existing cancel path; simpler than pause/resume. |
| Memory-fit check reuses `minRAMGB`. | Accepted | Consistent with the M13 picker's compatibility check. |
| Hardening decisions live as pure Kit logic; device signals fed in. | Accepted | Keeps it unit-testable without a device. |
