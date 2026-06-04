# Milestone 9 Plan

Date: 2026-06-04

Working name:

```txt
Transparent activity — verbose feed with inline animated visuals
```

## Status

Ready. Promoted from `docs/MILESTONE-9-PLANNING-DRAFT.md`.

## Goal

Surface what the pipeline is doing. Replace the plain, live-only,
buried-in-the-4th-tab activity log with a transparent, structured
**activity feed**: per-phase icons, counts, and a sticky Elo/pool
sparkline header, with animated row insertion — **persisted** on the run
snapshot so it is replayable after the run, not live-only.

## Design (resolved open questions)

- **Event granularity:** one `ActivityEvent` per progress callback; the
  event's `kind` drives compact per-row rendering.
- **Sparkline placement:** a sticky mini-chart header (top Elo / pool
  size) over the feed, reusing the Swift Charts work in `ChartsView`;
  compact counts per row.
- **Back-compat:** `RunSnapshot` gains an `activity` field via a custom
  `init(from:)` using `decodeIfPresent` → `[]`, so legacy saved runs
  decode cleanly.
- **Tool calls:** `ActivityEvent.Kind` includes `.tool` for future
  app-side tool runs; the current feed derives from `WorkflowProgress`
  (which carries no tool calls yet), so tool rows render when present but
  aren't synthesized here.

## Primary Scope (Execution Order)

Pure model + persistence first (testable), then the feed view.

### Track A — Structured, persisted activity model (AICoScientistKit)

1. `ActivityEvent` (Codable, Identifiable): step, phase, `kind`,
   iteration, detail, completed/total, optional topElo/poolSize. A
   `Kind(phase:)` mapping and `feed(from: [WorkflowProgress])` /
   `init(step:progress:)` builders. Pure, MLX-free, unit-tested.
2. `RunSnapshot.activity: [ActivityEvent]` with a custom `init(from:)`
   defaulting to `[]` for legacy snapshots; round-trip + legacy-decode
   tests.

### Track B — Rich activity feed view (Apps/macOS)

`WorkflowRunner` accumulates `[ActivityEvent]` (replacing the `[String]`
log) and writes them onto the snapshot on completion. `StudyDetailView`'s
activity tab becomes a feed of typed rows (per-phase icon, label, counts)
with a sticky Elo/pool sparkline header and animated insertion; it reads
live events while running and the persisted log afterward, and the tab is
auto-selected when a run starts.

## Definition Of Done

- `ActivityEvent.feed(from:)` derives a typed event list from a sequence
  of `WorkflowProgress` values (kind from phase, counts, top Elo, pool
  size, monotonic steps), unit-tested.
- `Kind(phase:)` maps known phases and falls back to `.other`, tested.
- `RunSnapshot` round-trips its `activity` through Codable, and a snapshot
  JSON without the field decodes to an empty log (back-compat), tested.
- The activity feed renders typed rows with icons + counts and a sticky
  Elo/pool sparkline; rows animate in; the feed is available after a run
  from the persisted log (manual verify, noted in closeout).
- No engine/run behavior changes beyond recording the event log.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green; macOS app builds.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M9 tracking + closeout docs land with the final commit.

## Non-Goals

- A bespoke animated hypothesis "board" or live graph animation — chosen
  direction is the feed with inline visuals.
- iOS activity feed — macOS first.
- New telemetry the engine doesn't already emit — derive from existing
  `WorkflowProgress`/metrics.
- Synthesizing tool-call rows — the `.tool` kind is ready, but the
  progress stream carries no tool calls yet (app runs don't enable tools).
