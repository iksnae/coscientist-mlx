# Milestone 22 Tracking

Date: 2026-06-05

Milestone:

```txt
Unidirectional state (Redux) — store, reducers, middleware; migrate run + settings + study
```

## Status

Delivered (code + tests). Tracks A–D landed; live behavior verification on a
device is operator-pending (build + unit tests only here).

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
| Generic `@Observable` Redux core (State, Action, Reducer, Store sync+async dispatch, async Middleware) in the Kit, unit-tested. | Done | `Sources/AICoScientistKit/Redux/Store.swift` + `StoreTests` (4); 167/40 green. |
| Run + download live state is a reduced `RunState`; visualizations render from it. | Done | `RunState`/`runReducer` + `RunStateTests`; `WorkflowRunner` projects it. |
| Settings + study title flow through reducers; UserDefaults persistence as side-effects; title-tracks-goal is a tested reducer. | Done | `SettingsState`/`settingsReducer`, `StudyTitle` + tests; stores run persistence side-effects. |
| Reducers test-first (mock, no GPU); side-effects only in the orchestrators. | Done | Reducer tests written before impl; stores hold side-effects. |
| No behavior regression: list/select/edit/run/results/settings on macOS + iOS. | Done (build) | Accessor names unchanged; both apps build. Live device check operator-pending. |
| `swift build` clean; `swift test` green; macOS + iOS build. | Done | 177 tests / 43 suites; both BUILD SUCCEEDED. |
| `import MLX*` only under `Sources/AICoScientistMLX/`. | Done | `git grep` → only `AICoScientistMLX/`. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean. |
| `swift test` | Passed | 177 tests / 43 suites (+14 across A–D). |
| macOS app build | Passed | BUILD SUCCEEDED. |
| iOS app build | Passed | BUILD SUCCEEDED. |
| `git diff --check` | Passed | Clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Redux core in AICoScientistKit on `@Observable` (not ObservableObject). | Accepted | Pure + testable; matches the app; avoids per-publish overhead. |
| Closure-based reducer + post-reduce async middleware. | Accepted | Ergonomic, composable; middleware is the side-effects seam the operator's post omitted. |
| Migrate run+settings+study; SwiftData stays the persistence/read model. | Accepted | Operator chose full migration; SwiftData remains for persistence/`@Query`. |
