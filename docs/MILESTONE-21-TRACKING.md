# Milestone 21 Tracking

Date: 2026-06-05

Milestone:

```txt
Professional UI redesign — main study view, sidebar, pickers, results
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | — |
| Elapsed | — |
| Scope class | Medium |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Sidebar studies are visually distinguishable (no row of identical titles for distinct studies). | Pending | |
| Each model picker shows the selected model inline; the strengths/fit caption appears once for the current choice. | Pending | |
| Results lead with a concise conclusion that is not a verbatim copy of the first hypothesis; long text truncates with expand. | Pending | |
| Run status copy is plain language and correctly pluralized (pure `RunStatusText`, unit-tested). | Pending | |
| `StudyDetailView` is split into small subviews (no oversized `body`); consistent spacing. | Pending | |
| No regression to run/results/inspector/activity; macOS + iOS build. | Pending | |
| `swift build` clean; `swift test` green. | Pending | |
| `import MLX*` only under `Sources/AICoScientistMLX/`. | Pending | |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | — | |
| `swift test` | — | |
| macOS app build | — | |
| iOS app build | — | |
| `git diff --check` | — | |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| New studies seed an empty goal; row shows title/"Untitled". | Accepted | Kills the row of identical "New research goal" seed titles. |
| Keep config visible + tidy (no collapse interaction this milestone). | Accepted | Avoids scope creep; run already disables controls. |
| Conclusion = synthesis-led + truncated top hypothesis (expandable). | Accepted | Removes verbatim duplication with the ranked list. |
| Pure `RunStatusText` in Kit, tested. | Accepted | Plain language + correct pluralization, mock-testable. |
