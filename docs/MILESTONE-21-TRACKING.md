# Milestone 21 Tracking

Date: 2026-06-05

Milestone:

```txt
Professional UI redesign — main study view, sidebar, pickers, results
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
| Sidebar studies are visually distinguishable (no row of identical titles for distinct studies). | Done | `Study.titleIsCustom` auto-tracks goal; new studies seed empty goal; `StudyRow` shows title/"Untitled". |
| Each model picker shows the selected model inline; the strengths/fit caption appears once for the current choice. | Done | `ModelChoicePicker` control shows title + model + chevron; concise caption; strengths in menu items. |
| Results lead with a concise conclusion that is not a verbatim copy of the first hypothesis; long text truncates with expand. | Done | `outcomeHeader` synthesis-led + truncated/expandable top hypothesis. |
| Run status copy is plain language and correctly pluralized (pure `RunStatusText`, unit-tested). | Done | `RunStatusText` + `RunStatusTextTests`; used in `statusLine`, `WorkflowRunner`, issues banner. |
| `StudyDetailView` is split into small subviews (no oversized `body`); consistent spacing. | Done | `ActivityFeedView` extracted; sectioned computed views; 8pt-ish rhythm. |
| No regression to run/results/inspector/activity; macOS + iOS build. | Done | Both BUILD SUCCEEDED; behavior preserved. |
| `swift build` clean; `swift test` green. | Done | 159 tests / 38 suites. |
| `import MLX*` only under `Sources/AICoScientistMLX/`. | Done | `git grep` → only the `Package.swift` comment. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean. |
| `swift test` | Passed | 159 tests / 38 suites (+2). |
| macOS app build | Passed | `CoScientistDemo` BUILD SUCCEEDED. |
| iOS app build | Passed | `CoScientistApp` BUILD SUCCEEDED. |
| `git diff --check` | Passed | Clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| New studies seed an empty goal; row shows title/"Untitled". | Accepted | Kills the row of identical "New research goal" seed titles. |
| Keep config visible + tidy (no collapse interaction this milestone). | Accepted | Avoids scope creep; run already disables controls. |
| Conclusion = synthesis-led + truncated top hypothesis (expandable). | Accepted | Removes verbatim duplication with the ranked list. |
| Pure `RunStatusText` in Kit, tested. | Accepted | Plain language + correct pluralization, mock-testable. |
