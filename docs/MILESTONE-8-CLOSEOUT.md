# Milestone 8 Closeout

Date: 2026-06-04

Milestone:

```txt
Hypothesis selection + inspector
```

## Status

Complete.

## Delivered

### Track A — Pure projection + selection model (AICoScientistKit)

- `HypothesisDetail` (`Sources/AICoScientistKit/Core/HypothesisDetail.swift`):
  projects a `Hypothesis` into inspector sections — metrics (elo, score,
  win/loss, win rate, matches), cluster, lineage (`evolutionHistory`),
  latest review (six `ReviewScores` dimensions + summary/strengths/
  weaknesses/suggestions/safety) and review count. Pure, MLX-free.
- `GraphSelection.resolve(nodeID:in:)`: maps a graph node id (hypothesis
  UUID / `cluster:<cid>` / phase id) to a typed selection, nil for
  unknown. Pure, unit-tested.

### Track B — Selectable list + graph + shared inspector (Apps/macOS)

- `HypothesisInspector` (`Apps/macOS/HypothesisInspector.swift`): a
  trailing inspector rendering `HypothesisDetail` — metric row, score
  bars for the six dimensions, the latest review's summary + qualitative
  lists, and the evolution lineage.
- `StudyDetailView`: the Hypotheses list is now selectable
  (`List(selection:)`), and both the list and graph share the inspector
  via an `inspectorSplit` (animated). Works on live state and the
  persisted snapshot.
- `GraphView`: tappable nodes via Grape's `graphOverlay` +
  `GraphProxy.node(at:)` → `GraphSelection.resolve`, driving the same
  inspector; the selected node is outlined. `simultaneousGesture` so the
  graph's pan/zoom still work.

Not in scope despite being adjacent: iOS inspector, editing/re-running
from the inspector, activity transparency (M9), and graph layout changes.

## Validation

```txt
swift build                          # clean on Apple Silicon
swift test                           # 127 tests / 27 suites green (+4)
xcodebuild … -scheme CoScientistDemo # macOS app BUILD SUCCEEDED
git grep "import MLX" -- '*.swift'   # only AICoScientistMLX + Package.swift
git diff --check                     # whitespace clean
```

## Retrospective

What worked:

- Putting `HypothesisDetail` + `GraphSelection` in Kit made the inspector
  content and the graph node-id → detail mapping fully unit-testable; the
  SwiftUI views ended up thin renderers.
- One shared inspector serves both the list and the graph, so list and
  graph selection are consistent with no duplicated rendering.
- Grape's `graphOverlay` + `GraphProxy.node(at:)` gave node tap-selection
  without forking Grape; `simultaneousGesture` preserved pan/zoom.

What to improve:

- New SwiftUI files need `xcodegen generate` before they're in the target
  — the first app build failed on a missing file until regeneration.
  A `bootstrap`/predictable regen step would smooth this (carry-forward).
- Graph tap-selection is verified by build + the pure resolver's tests;
  the tap hit-testing itself is manual-verify (no app UI test target).
- Cluster/operation node taps resolve but don't yet have a dedicated
  inspector panel (only hypothesis selection drives the inspector).

Carry forward (M9 candidates):

- Transparent activity — verbose, persisted feed with per-phase icons,
  counts, tool calls, inline animated sparklines (M9, drafted).
- A cluster/operation inspector panel (taps already resolve to typed
  selections).
- Optional `bootstrap.sh` / documented regen so new app files land in the
  Xcode target without a surprise build failure.
