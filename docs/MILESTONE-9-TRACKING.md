# Milestone 9 Tracking

Date: 2026-06-04

Milestone:

```txt
Transparent activity — verbose feed with inline animated visuals
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
| `ActivityEvent.feed(from:)` derives a typed event list (kind, counts, top Elo, pool size, monotonic steps) from `WorkflowProgress`. | Done | `ActivityEventTests.feedDerives` (9b46777) |
| `Kind(phase:)` maps known phases and falls back to `.other`. | Done | `ActivityEventTests.unknownKind` (9b46777) |
| `RunSnapshot` round-trips `activity`; a JSON without the field decodes to an empty log. | Done | `ActivityEventTests.snapshotRoundTrip` + `legacyDecodes` (9b46777) |
| The activity feed renders typed rows + sticky sparkline, animates in, and is available after a run from the persisted log. | Done | `StudyDetailView.activityList` (9724d1d); macOS BUILD SUCCEEDED |
| No engine/run behavior change beyond recording the event log. | Done | Only `WorkflowRunner` records events; snapshot field is additive. |
| New behaviour is driven by a test written first (mock backend, no GPU). | Done | `ActivityEventTests` written before impl. |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Done | `git grep "import MLX" -- '*.swift'` → only adapter + `Package.swift`. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on Apple Silicon. |
| `swift test` | Passed | 131 tests / 28 suites green (+4). |
| macOS app build | Passed | `xcodebuild … CoScientistDemo` BUILD SUCCEEDED. |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| One `ActivityEvent` per progress callback. | Accepted | Simple, faithful; `kind` drives compact rendering. |
| `RunSnapshot.activity` via custom `init(from:)` + decodeIfPresent. | Accepted | Back-compat: legacy snapshots decode to an empty log. |
| Sticky Elo/pool sparkline header (reuse `ChartsView`). | Accepted | Inline visual without per-row chart cost. |
