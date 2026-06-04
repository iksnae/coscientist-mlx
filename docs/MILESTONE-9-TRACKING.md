# Milestone 9 Tracking

Date: 2026-06-04

Milestone:

```txt
Transparent activity — verbose feed with inline animated visuals
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
| `ActivityEvent.feed(from:)` derives a typed event list (kind, counts, top Elo, pool size, monotonic steps) from `WorkflowProgress`. | Pending | Track A |
| `Kind(phase:)` maps known phases and falls back to `.other`. | Pending | Track A |
| `RunSnapshot` round-trips `activity`; a JSON without the field decodes to an empty log. | Pending | Track A |
| The activity feed renders typed rows + sticky sparkline, animates in, and is available after a run from the persisted log. | Pending | Track B |
| No engine/run behavior change beyond recording the event log. | Pending | Track B |
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
| One `ActivityEvent` per progress callback. | Accepted | Simple, faithful; `kind` drives compact rendering. |
| `RunSnapshot.activity` via custom `init(from:)` + decodeIfPresent. | Accepted | Back-compat: legacy snapshots decode to an empty log. |
| Sticky Elo/pool sparkline header (reuse `ChartsView`). | Accepted | Inline visual without per-row chart cost. |
