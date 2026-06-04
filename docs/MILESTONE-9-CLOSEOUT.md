# Milestone 9 Closeout

Date: 2026-06-04

Milestone:

```txt
Transparent activity — verbose feed with inline animated visuals
```

## Status

Complete.

## Delivered

### Track A — Structured, persisted activity model (AICoScientistKit)

- `ActivityEvent` (`Sources/AICoScientistKit/Engine/ActivityEvent.swift`):
  a Codable, Identifiable row — step, phase, `Kind` (phase family for the
  icon, incl. `.tool`/`.other`), iteration, detail, completed/total, and
  optional top Elo / pool size. `Kind(phase:)`, `init(step:progress:)`,
  and `feed(from: [WorkflowProgress])`. Pure, unit-tested.
- `RunSnapshot.activity: [ActivityEvent]` with a tolerant `init(from:)`
  (`decodeIfPresent → []`), so the feed persists with a run and legacy
  snapshots still decode. Round-trip + legacy-decode tests.

### Track B — Rich activity feed view (Apps/macOS)

- `WorkflowRunner` accumulates `[ActivityEvent]` (replacing the `[String]`
  log) with a monotonic step counter and writes them onto the snapshot on
  completion.
- `StudyDetailView`'s Activity tab is now a feed of typed rows (per-phase
  SF Symbol, phase, iteration, counts, detail, top Elo) with a sticky
  header showing a top-Elo sparkline (Swift Charts) + pool size, animated
  row insertion, and auto-scroll. It reads live events while running and
  the persisted log afterward, and the tab auto-selects when a run starts.

Not in scope despite being adjacent: a bespoke animated hypothesis board /
live graph animation, an iOS feed, and synthesized tool-call rows (the
`.tool` kind exists but the progress stream carries no tool calls yet).

## Validation

```txt
swift build                          # clean on Apple Silicon
swift test                           # 131 tests / 28 suites green (+4)
xcodebuild … -scheme CoScientistDemo # macOS app BUILD SUCCEEDED
git grep "import MLX" -- '*.swift'   # only AICoScientistMLX + Package.swift
git diff --check                     # whitespace clean
```

## Retrospective

What worked:

- Deriving the feed from the existing `WorkflowProgress` stream meant no
  engine change — `ActivityEvent` is a pure projection, fully unit-tested,
  and the view is a thin renderer.
- The tolerant `RunSnapshot.init(from:)` made the schema change safe for
  existing saved runs, proven by a legacy-decode test that strips the
  field from encoded JSON.
- Persisting the log turned activity from live-only into a replayable
  record — the operator's core "it's buried / vanishes" complaint.

What to improve:

- Tool-call rows aren't synthesized — app runs don't enable tools yet, so
  the `.tool` kind is unused. Wiring the M6 `onToolCall` hook into the app
  runner would light it up (carry-forward).
- The feed caps at 200 retained rows (as the old log did); very long runs
  drop the oldest live rows, though the persisted snapshot keeps the tail.
- Activity is macOS-only; iOS still has no feed.

Carry forward (M10 candidates):

- M10 — Foundation Models backend (drafted, deferred from M8).
- Wire app-side tool runs (M6 `--tools` equivalent) so the feed shows
  `.tool` rows.
- iOS activity feed + inspector parity.
