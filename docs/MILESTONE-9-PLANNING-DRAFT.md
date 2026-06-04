# Milestone 9 Planning Draft

Date: 2026-06-04

Working name:

```txt
Transparent activity — verbose feed with inline animated visuals
```

## Status

Draft. Not yet promoted to MILESTONE-9-PLAN.md.

## Goal

Surface what the pipeline is doing. Today activity is a plain monospace
log buried in the 4th tab that only exists *while running* and vanishes
afterward. M9 turns it into a transparent, structured **activity feed**:
per-phase icons, counts, tool calls, and inline sparklines (Elo / pool
size) with animated row insertion — and it is **persisted** so the feed
is replayable after the run, not live-only.

## Context

Operator signal (2026-06-04): *"the activity is buried … make activity
more transparent, like the activity feed but verbose and graphical
visualization that animates state change."* Chosen direction: a
feed-centric rich timeline with inline visuals (not a bespoke board, not
graph animation). Today `WorkflowRunner.activity` is `[String]` built in
`apply(_:)` from `WorkflowProgress` and shown live-only in
`StudyDetailView.activityList`; `RunSnapshot` does not store it. The data
to drive a rich feed already flows through `WorkflowProgress` (phase,
iteration, detail, completed/total, hypotheses, metrics) and the runner's
`timeline` (top/avg Elo, pool size).

## Usage Scenarios

### Scenario 1: Watch a run unfold

Expected behavior:

- Each pipeline step appears as a feed row with a per-phase icon, a
  human label, counts (e.g. "reflection 3/6"), and any tool calls
  ("arxiv_search — …" from M6's hook).
- Rows animate in; Elo/pool sparklines update inline as state changes.

### Scenario 2: Review activity after the run

Expected behavior:

- After a completed (or cancelled) study, the activity feed is still
  there — rebuilt from the persisted event log on the snapshot — so you
  can scroll the full history, not just a live tail.

## Primary Scope

### Track A — Structured, persisted activity model (AICoScientistKit)

A typed `ActivityEvent` (phase, iteration, detail, a `kind` for the icon,
completed/total, optional tool-call label, optional metric deltas) and a
builder that derives `[ActivityEvent]` from the progress stream. Persist
the event log on `RunSnapshot` (optional/default-empty for back-compat),
so the feed survives the run. Pure, MLX-free, unit-tested.

### Track B — Rich activity feed view (Apps/macOS)

Replace the plain `activityList` with a feed of typed rows: per-phase
icon, label, counts, tool calls, and inline sparklines (reusing the
Swift Charts work from `ChartsView`), with animated insertion. Make it
prominent (default-select the tab when a run starts) and drive it from
live events while running and from the persisted log afterward. The
WorkflowRunner accumulates `[ActivityEvent]` (replacing the `[String]`
log) and writes them onto the snapshot on completion.

## Definition Of Done

- `ActivityEvent` + the builder derive a typed event list from a sequence
  of `WorkflowProgress` values (phase/kind/counts/tool-call), unit-tested.
- `RunSnapshot` round-trips its activity log through Codable; an old
  snapshot without the field decodes to an empty log (back-compat),
  unit-tested.
- The activity feed renders typed rows with icons, counts, tool calls and
  inline sparklines; rows animate in (manual verify, noted in closeout).
- The feed is available after a run from the persisted log, not live-only.
- No engine/run behavior changes beyond recording the event log.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M9 tracking + closeout docs land with the final commit.

## Non-Goals

- A bespoke animated hypothesis "board" or live graph animation — chosen
  direction is the feed with inline visuals.
- iOS activity feed — macOS first.
- New telemetry the engine doesn't already emit — derive from existing
  `WorkflowProgress`/metrics.

## Open Questions

- **Event granularity.** One event per progress callback vs. coalescing
  per-match spam into a rolled-up "tournament round" row. Lean one event
  per callback, with the `kind` driving compact rendering. Delivery detail.
- **Sparkline placement.** Inline per-row vs. a sticky mini-chart header
  over the feed. Lean a sticky header (Elo/pool) + compact per-row counts.
  Delivery detail.

## Risk

- **Snapshot schema change.** Adding the activity log to `RunSnapshot`
  must not break existing saved runs. Mitigate with an optional field
  defaulting to empty + a decode test for the legacy shape.
- **Feed volume.** Long runs emit many events. Mitigate by capping the
  retained/rendered list (as the current log does) and noting any cap.

## Scope Class

Small. One pure event model + snapshot field + a richer feed view reusing
existing charts; no engine, adapter, or network work.

Estimated 3–4 commits (Track A) + 3–4 (Track B), ~6–8 commits.
