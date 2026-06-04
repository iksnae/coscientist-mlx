# Milestone 8 Planning Draft

Date: 2026-06-04

Working name:

```txt
Hypothesis selection + inspector
```

## Status

Draft. Not yet promoted to MILESTONE-8-PLAN.md.

## Goal

Make study results explorable. Today the Hypotheses tab is a flat,
read-only list and the Graph is non-interactive — you can't drill into a
hypothesis to understand *why* it ranked where it did. M8 adds selection
(in the results list and the graph) and a detail **inspector** that shows
a hypothesis's full story: text, score breakdown across the review
dimensions, the peer reviews (summary / strengths / weaknesses / safety),
its win/loss tournament record, cluster, and evolution lineage. Selecting
a node in the graph opens the same inspector.

## Context

Operator signal (2026-06-04): *"we're not really presenting the results
of the study … we need selection and an inspector for the hypothesis."*
This supersedes and expands the earlier M9 draft (graph node selection +
inspector) — the inspector should serve both the list and the graph. The
data is already rich: `Hypothesis`
(`Sources/AICoScientistKit/Core/Hypothesis.swift`) carries `reviews:
[HypothesisReview]` (six 0–1 dimensions + summary/strengths/weaknesses/
safety), `evolutionHistory`, `winCount`/`lossCount`/`winRate`, `score`,
and `similarityClusterID` — none of which the current
`StudyDetailView.hypothesesList` surfaces.

## Usage Scenarios

### Scenario 1: Inspect a ranked hypothesis from the list

Expected behavior:

- Clicking a row in the Hypotheses list selects it and opens an inspector
  showing its text, per-dimension score breakdown, each review's
  summary/strengths/weaknesses, win/loss record + win rate, cluster, and
  evolution lineage.
- Works on the persisted snapshot (after a run) and on live state.

### Scenario 2: Inspect from the graph

Expected behavior:

- Selecting a hypothesis node in the Graph opens the same inspector for
  that hypothesis; a cluster hub shows its members; an operation node
  shows its phase/timing.
- Clicking empty space clears the selection.

## Primary Scope

### Track A — Pure projection + selection model (AICoScientistKit)

A pure `HypothesisDetail` projection that turns a `Hypothesis` into typed
inspector sections (score breakdown, reviews, record, cluster, lineage) —
MLX-free, unit-tested, no SwiftUI. Plus a `RunGraph` model (typed nodes:
operation / hypothesis / cluster, + edges) and a selection→detail mapping
(selected node id → the typed inspector model), so the graph's data shape
is testable rather than buried in the view.

### Track B — Selectable list + graph + shared inspector (Apps/macOS)

Add selection state to `StudyDetailView.hypothesesList` and `GraphView`,
and a shared inspector pane that renders the Track A `HypothesisDetail`.
SwiftUI stays thin — it consumes the pure models and holds only view
state. The inspector is reused across the list and graph selections.

## Definition Of Done

- `HypothesisDetail` projects a `Hypothesis` into the inspector sections
  (score breakdown, reviews, record, cluster, lineage), unit-tested.
- `RunGraph` builds typed nodes + edges from a sample snapshot, and the
  selection→detail mapping returns the right detail per node kind (and
  nil for no selection), unit-tested.
- Selecting a hypothesis (list or graph) opens the inspector for it;
  clearing selection closes it (manual verify, noted in closeout).
- The inspector works on both the persisted snapshot and live state; no
  engine/run behavior changes — results are derived, read-only.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M8 tracking + closeout docs land with the final commit.

## Non-Goals

- iOS inspector — macOS first; iOS can follow.
- Editing/re-running from the inspector — inspection only.
- Activity transparency / animated feed — that is M9.
- Graph layout/algorithm changes — Grape layout stays as shipped.

## Open Questions

- **Inspector placement.** A trailing inspector pane vs. a sheet/popover.
  Lean a trailing pane (room for reviews + lineage). Delivery detail.
- **Score breakdown source.** Average across reviews vs. latest review's
  dimensions. Lean show the latest review's six dimensions plus the
  aggregate `score`. Delivery detail.

## Risk

- **UI logic resisting TDD.** Push all derivable logic (projection, graph
  build, selection mapping) into the Track A pure models; keep the view a
  thin consumer — the testable surface is the model, not the view.

## Scope Class

Small. Pure projection/graph models + a thin selectable view + shared
inspector; no engine, adapter, or network work.

Estimated 3–4 commits (Track A) + 3–4 (Track B), ~6–8 commits.
