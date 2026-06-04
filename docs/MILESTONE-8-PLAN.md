# Milestone 8 Plan

Date: 2026-06-04

Working name:

```txt
Hypothesis selection + inspector
```

## Status

Ready. Promoted from `docs/MILESTONE-8-PLANNING-DRAFT.md`.

## Goal

Make study results explorable. Add selection (results list + graph) and a
detail **inspector** showing a hypothesis's full story: text, score
breakdown across the six review dimensions, the peer reviews
(summary / strengths / weaknesses / suggestions / safety), tournament
win/loss record, cluster, and evolution lineage. Selecting a node in the
graph opens the same inspector.

## Design (resolved open questions)

- **Inspector placement:** a trailing inspector pane beside the list /
  graph (room for reviews + lineage).
- **Score breakdown source:** the latest review's six `ReviewScores`
  dimensions + its `overall`, plus the hypothesis-level aggregate `score`
  and a review count. (`Hypothesis.reviews` is the source; the last entry
  is the most recent.)
- **Node-id scheme (already in `GraphView`):** hypothesis = `id.uuidString`,
  cluster = `cluster:<cid>`, operation = phase id. The pure resolver parses
  these, so it is testable independently of Grape.
- **Graph tap:** Grape's `GraphProxy.node(at:)` maps a tap point to a node
  id; the pure resolver turns that id into the inspector selection.

## Primary Scope (Execution Order)

Pure models first (testable, no UI), then the views that consume them.

### Track A — Pure projection + selection model (AICoScientistKit)

1. `HypothesisDetail` — projects a `Hypothesis` into inspector sections:
   identity (text), metrics (elo, score, win/loss, winRate, totalMatches),
   cluster, lineage (`evolutionHistory`), latest review (six dimensions +
   overall + summary/strengths/weaknesses/suggestions/safety) and review
   count. Pure, MLX-free.
2. `GraphSelection` + `resolve(nodeID:in:)` — maps a graph node id to
   `.hypothesis(HypothesisDetail)`, `.cluster(id, memberCount)`,
   `.operation(phase)`, or `nil`. Pure, unit-tested.

### Track B — Selectable list + graph + shared inspector (Apps/macOS)

A shared `HypothesisInspector` view rendering `HypothesisDetail`. Add
selection to `StudyDetailView.hypothesesList` (selectable rows → trailing
inspector). Add tap selection to `GraphView` via `GraphProxy.node(at:)`,
resolving through Track A into the same inspector and highlighting the
selected node. Selection state lives in the view; data comes from the
pure models.

## Definition Of Done

- `HypothesisDetail` projects a `Hypothesis` into the inspector sections
  (metrics, latest review's six dimensions + overall, qualitative lists,
  cluster, lineage, review count), unit-tested.
- `resolve(nodeID:in:)` returns the right selection for a hypothesis id,
  a `cluster:<cid>` id, an operation/phase id, and `nil` for unknown,
  unit-tested.
- Selecting a hypothesis row opens the inspector for it; the graph maps a
  tapped node to the same inspector (manual verify, noted in closeout).
- The inspector works on both the persisted snapshot and live state; no
  engine/run behavior changes — results are derived, read-only.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green; macOS app builds.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M8 tracking + closeout docs land with the final commit.

## Non-Goals

- iOS inspector — macOS first.
- Editing/re-running from the inspector — inspection only.
- Activity transparency / animated feed — that is M9.
- Graph layout/algorithm changes — Grape layout stays as shipped.
