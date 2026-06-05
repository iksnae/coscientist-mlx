# Milestone 14 Tracking

Date: 2026-06-05

Milestone:

```txt
Run config + results outcome (macOS)
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
| Scope class | Small-to-Medium |
| Confidence | High |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| The `Study` stores survivors (evolutionTopK) + tournament size (defaulted; existing studies load), and `WorkflowRunner` applies them to `EngineConfiguration`. | Done | `Study` fields + `WorkflowRunner` config init (620c8c1) |
| The Advanced section exposes survivors + tournament size with plain one-line copy + defaults; collapsed by default. | Done | `StudyDetailView` Advanced DisclosureGroup (620c8c1) |
| `RunSnapshot.conclusion` (top hypothesis + meta-review synthesis) is a pure projection, unit-tested; empty meta-review ⇒ top hypothesis alone. | Done | `RunConclusionTests` (3149276) |
| A finished study shows an outcome header stating the conclusion above the list; running/empty states handled. | Done | `StudyDetailView.outcomeHeader` (620c8c1); shown only when `!live` + hasResult |
| No engine behavior change beyond honoring the exposed config. | Done | Config values only; `swift test` green. |
| New logic is test-first (mock, no GPU). | Done | `RunConclusionTests` written before impl. |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Done | `git grep` → only `Package.swift` comment. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on Apple Silicon. |
| `swift test` | Passed | 145 tests / 34 suites green (+2). |
| macOS app build | Passed | `xcodebuild … CoScientistDemo` BUILD SUCCEEDED. |
| iOS app build | Passed | `xcodebuild … CoScientistApp` BUILD SUCCEEDED (shared views unbroken). |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Expose survivors + tournament size; defer tool-steps. | Accepted | Both have a real run effect; tool-steps is inert until tools are app-enabled. |
| Outcome = top hypothesis + meta-review synthesis (pure `RunSnapshot.conclusion`). | Accepted | States the conclusion; testable; falls back to top hypothesis when synthesis is empty. |
