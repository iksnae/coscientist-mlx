# Milestone 8 Tracking

Date: 2026-06-04

Milestone:

```txt
Hypothesis selection + inspector
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-04 |
| Actual start | 2026-06-04 |
| Actual end | TBD |
| Elapsed | TBD |
| Scope class | Small |
| Confidence | High |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| `HypothesisDetail` projects a `Hypothesis` into inspector sections (metrics, latest review six dims + overall, qualitative lists, cluster, lineage, review count). | Pending | Track A |
| `resolve(nodeID:in:)` returns the right selection for hypothesis / cluster / operation ids and nil for unknown. | Pending | Track A |
| Selecting a hypothesis row opens the inspector; the graph maps a tapped node to the same inspector. | Pending | Track B |
| The inspector works on the persisted snapshot and live state; no engine/run change. | Pending | Track B |
| New behaviour is driven by a test written first (mock backend, no GPU). | Pending | all tracks |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Pending | `git grep` check |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Pending | — |
| `swift test` | Pending | — |
| macOS app build | Pending | — |
| `git diff --check` | Pending | — |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Pure `HypothesisDetail` + `GraphSelection` in Kit. | Accepted | Keeps inspector/selection logic testable; SwiftUI stays a thin consumer. |
| Inspector = trailing pane; score breakdown = latest review + aggregate score. | Accepted | Room for reviews + lineage; latest review is the most recent assessment. |
| Graph tap via `GraphProxy.node(at:)` → pure resolver. | Accepted | Reuses Grape's hit-testing; the id→detail mapping is unit-tested. |
