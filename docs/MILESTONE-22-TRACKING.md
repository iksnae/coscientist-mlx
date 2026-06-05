# Milestone 22 Tracking

Date: 2026-06-05

Milestone:

```txt
Unidirectional state (Redux) — store, reducers, middleware; migrate run + settings + study
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | — |
| Elapsed | — |
| Scope class | Large |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Generic `@Observable` Redux core (State, Action, Reducer, Store sync+async dispatch, async Middleware) in the Kit, unit-tested. | Pending | |
| Run + download live state is a reduced `RunState`; visualizations + byte-reactive download render from it. | Pending | |
| Settings + study selection/editing flow through actions; UserDefaults + SwiftData persistence in middleware; title-tracks-goal is a tested reducer. | Pending | |
| Reducers test-first (mock, no GPU); side-effects only in middleware. | Pending | |
| No behavior regression: list/select/edit/run/results/settings on macOS + iOS. | Pending | |
| `swift build` clean; `swift test` green; macOS + iOS build. | Pending | |
| `import MLX*` only under `Sources/AICoScientistMLX/`. | Pending | |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | — | |
| `swift test` | — | |
| macOS app build | — | |
| iOS app build | — | |
| `git diff --check` | — | |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Redux core in AICoScientistKit on `@Observable` (not ObservableObject). | Accepted | Pure + testable; matches the app; avoids per-publish overhead. |
| Closure-based reducer + post-reduce async middleware. | Accepted | Ergonomic, composable; middleware is the side-effects seam the operator's post omitted. |
| Migrate run+settings+study; SwiftData stays the persistence/read model. | Accepted | Operator chose full migration; SwiftData remains for persistence/`@Query`. |
