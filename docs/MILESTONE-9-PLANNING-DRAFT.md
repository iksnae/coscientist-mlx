# Milestone 9 Planning Draft

Date: 2026-06-04

Working name:

```txt
Graph node selection + details inspector
```

## Status

Draft. Not yet promoted to MILESTONE-9-PLAN.md.

## Goal

Make the node-graph view (shipped in PR #28, `Apps/macOS/GraphView.swift`)
interactive: click a node to select it and see its details in an inspector
pane. A pipeline-operation node reveals its phase and timing; a hypothesis
node reveals text, Elo, win rate, and cluster; a cluster hub reveals its
members. The graph becomes a way to *explore* a run, not just look at it.

## Operator signal

Requested directly during batch planning ("Enable selection + details
inspector in graph") — an addition to the agent-research and optimization
themes, picking up the just-shipped Grape node graph.

## Context

PR #28 added a Graph tab with a live-highlighted pipeline operation graph
and an artifacts graph (hypotheses sized by Elo, linked to cluster hubs),
both rendered with Grape. It is read-only — nodes can't be selected and
there's no way to inspect a node's underlying data. All the data already
exists in the run snapshot/artifacts consumed by the view; this milestone
adds selection state and a detail surface over that existing data, with
the graph-shaping logic extracted into a pure, testable model.

## Usage Scenarios

### Scenario 1: Inspect a hypothesis node

Expected behavior:

- Clicking a hypothesis node selects it (visually distinct) and opens an
  inspector showing its text, Elo, win rate, and cluster id.
- Clicking empty space (or a deselect affordance) clears the selection.

### Scenario 2: Inspect a pipeline operation / cluster hub

Expected behavior:

- Selecting an operation node shows its phase name and recorded timing.
- Selecting a cluster hub lists the hypotheses that belong to it.
- The inspector reflects selection changes immediately; no run re-trigger.

## Primary Scope

### Track A — Pure graph + selection model (AICoScientistKit)

Extract the graph-building (RunSnapshot/artifacts → nodes + edges, with a
node `kind`: operation / hypothesis / cluster) into a pure `RunGraph`
model in the domain layer, plus a selection→inspector mapping (selected
node id → a typed inspector view-model). Domain-only, MLX-free,
unit-tested — this also retroactively makes the graph's data shape
testable rather than buried in SwiftUI.

### Track B — Interactive view + inspector (Apps/macOS)

Add selection state to `GraphView` (tap to select, highlight the selected
node, tap-away to clear) and an inspector pane that renders the Track A
inspector model. SwiftUI stays thin — it consumes the pure model and
holds only view state.

## Definition Of Done

- `RunGraph` builds typed nodes (operation / hypothesis / cluster) and
  edges from a sample run snapshot (unit-tested, no UI).
- The selection→inspector mapping returns the correct typed detail for
  each node kind and `nil`/empty for no selection (unit-tested).
- Clicking a node selects + highlights it; the inspector shows that
  node's details; clicking away clears the selection (manual verify,
  noted in closeout).
- No engine or run behavior changes — graph data is derived, read-only.
- New behaviour is driven by a test written first (mock backend, no GPU)
  for the Track A model/mapping.
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M9 tracking + closeout docs land with the final commit.

## Non-Goals

- iOS graph interactivity — macOS first; iOS can follow if wanted.
- Editing/re-running from the graph — inspection only, no mutation.
- Graph layout/algorithm changes — Grape layout stays as shipped.
- Exporting the graph as an image — out of scope.

## Open Questions

- **Where `RunGraph` lives.** Domain layer (Kit) makes it testable and
  reusable across macOS/iOS; an app-local model would not be in the
  `swift test` path. Lean Kit, so the DoD's test-first rule is honest.
- **Inspector placement.** A trailing inspector pane vs. a popover on the
  node. Lean a trailing pane (room for cluster member lists). Delivery
  detail.

## Risk

- **UI logic resisting TDD.** Pure SwiftUI is hard to unit-test.
  Mitigate by pushing all derivable logic (graph build + selection
  mapping) into the Track A pure model and keeping the view a thin
  consumer — the testable surface is the model, not the view.

## Scope Class

Small. One pure model extraction + a thin interactive view; no engine,
adapter, or network work.

Estimated 3–4 commits (Track A) + 2–3 (Track B), ~5–7 commits.
