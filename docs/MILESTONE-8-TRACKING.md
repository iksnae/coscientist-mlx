# Milestone 8 Tracking

Date: 2026-06-04

Milestone:

```txt
Hypothesis selection + inspector
```

## Status

Complete

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-04 |
| Actual start | 2026-06-04 |
| Actual end | 2026-06-04 |
| Elapsed | same day |
| Scope class | Small |
| Confidence | High |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| `HypothesisDetail` projects a `Hypothesis` into inspector sections (metrics, latest review six dims + overall, qualitative lists, cluster, lineage, review count). | Done | `HypothesisDetailTests.projects` (14d8bb2) |
| `resolve(nodeID:in:)` returns the right selection for hypothesis / cluster / operation ids and nil for unknown. | Done | `HypothesisDetailTests` resolve* (14d8bb2) |
| Selecting a hypothesis row opens the inspector; the graph maps a tapped node to the same inspector. | Done | `StudyDetailView` list selection + `GraphView` tap (c2c1ff9); macOS BUILD SUCCEEDED |
| The inspector works on the persisted snapshot and live state; no engine/run change. | Done | `selectedDetail` reads `hypotheses` (live or snapshot); read-only. |
| New behaviour is driven by a test written first (mock backend, no GPU). | Done | `HypothesisDetailTests` written before impl. |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Done | `git grep "import MLX" -- '*.swift'` → only adapter + `Package.swift`. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on Apple Silicon. |
| `swift test` | Passed | 127 tests / 27 suites green (+4). |
| macOS app build | Passed | `xcodebuild … CoScientistDemo` BUILD SUCCEEDED. |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Pure `HypothesisDetail` + `GraphSelection` in Kit. | Accepted | Keeps inspector/selection logic testable; SwiftUI stays a thin consumer. |
| Inspector = trailing pane; score breakdown = latest review + aggregate score. | Accepted | Room for reviews + lineage; latest review is the most recent assessment. |
| Graph tap via `GraphProxy.node(at:)` → pure resolver. | Accepted | Reuses Grape's hit-testing; the id→detail mapping is unit-tested. |
