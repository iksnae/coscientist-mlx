# Milestone 22 Planning Draft

Date: 2026-06-05

Working name:

```txt
Unidirectional state (Redux) — store, reducers, middleware; migrate run + settings + study
```

## Status

Ready. Delivering incrementally: Track A (core) → B (run+download) → C
(settings) → D (study), each landing green in small commits.

## Goal

Adopt a unidirectional **Redux-style** state architecture so app state is a
single source of truth, mutated only through actions + pure reducers, with
side-effects isolated in async middleware. This makes the live run/download
state that drives the realtime visualizations predictable and testable, and
fixes the download progress that "isn't reactive to data." Port the
operator's pattern (https://iksnae.com/2022/12/04/swift-redux-protocols/),
adapted to Swift 6 + the modern `@Observable`, and migrate the app's state
(run, download, settings, and study selection/editing) onto it.

## Context

Operator (2026-06-05): wants "to manage app state properly and support
realtime animations + visualizations," via their own Redux pattern —
`StateType`/`ActionType` markers, `Reducer<T>` (`reduce(_:_:) -> T`),
`Store<T>` (their post uses `ObservableObject`; we'll use `@Observable`),
`@MainActor dispatch(_:)` + an `async` variant, and `SceneLogic` for wiring.
The post omits middleware / side-effects / realtime specifics — those are
the design gaps.

Today the app uses ad-hoc `@Observable` stores: `WorkflowRunner` mutates
~12 vars directly from the engine progress callback + the model-download
closure; `SettingsStore` mutates many fields; views mutate `Study`
directly. Mutation is scattered, and the live state feeding the Elo
sparkline, `GraphView`, `ChartsView`, the download `ProgressView`, and
`ActivityFeedView` is hard to reason about. HF download progress is reported
per-file (coarse), so the bar lurches rather than animating.

Settled with the operator: the Redux core lives in **`AICoScientistKit`**
(pure, unit-tested); migrate **run + download + settings + study** state in
this milestone; sequence this **next** (the parked M19 LAN-offload stays
drafted). **Study persistence stays SwiftData/CloudKit** (M16/M17) — the
store owns selection/editing/run state and dispatches persistence as a
middleware side-effect; it does not replace the SwiftData store.

## Usage Scenarios

### Scenario 1: Smooth, data-driven run + download

Expected behavior:

- During a run, the sparkline/graph/charts/activity update from one
  `RunState`; the download bar advances from real byte-level progress
  (smooth, not lurching), all flowing actions → reducer → store → views.

### Scenario 2: Predictable, testable state

Expected behavior:

- Every state change is an `Action` reduced by a pure `Reducer` (unit-tested
  with the mock backend); side-effects (engine run, model download, byte
  progress, persistence) live only in async middleware.

### Scenario 3: No behavior regressions

Expected behavior:

- Studies list/select/edit/run/results/settings behave exactly as before on
  macOS + iOS; the refactor is internal.

## Primary Scope

Ordered so each track lands in small commits and is independently green.

### Track A — Redux core in AICoScientistKit

`StateType`/`ActionType`, `Reducer` (pure `(Action, State) -> State`), an
`@Observable Store` with `@MainActor dispatch(_:)` + `async dispatch`, and
**async `Middleware`** (the missing piece: intercept actions, run
side-effects, dispatch follow-up actions). Generic + UI-free; unit-tested
(dispatch → reducer → state; middleware ordering). No MLX, no IO in reducers.

### Track B — Run + download state → store

A `RunState` (phase, counts, hypotheses, metrics, activity, timeline,
errors, download progress) reduced from engine/download **Actions**.
`WorkflowRunner` becomes thin: middleware runs the engine + downloads and
dispatches progress actions; the views (`StudyDetailView`, `ActivityFeedView`,
`ChartsView`, `GraphView`) read `RunState`. Download progress becomes
**byte-reactive** (stream real fraction, not per-file jumps).

### Track C — Settings state → store

Provider/model/embedder state (`SettingsStore`) reduced via actions;
**persistence (UserDefaults) + HF env (`HF_HUB_CACHE`, token) move into
middleware**; `hostedModelOptions`/`ensureModelsLoaded` become
selectors/middleware. Behavior unchanged.

### Track D — Study selection/editing → store

Study **selection, editing (title/goal), and CRUD intent** flow through
actions; **SwiftData remains the persistence layer** — middleware writes to
the `ModelContext` (and the `@Query` list stays the read model, or is read
into state via a load action). The title-auto-tracks-goal logic moves into a
reducer (also fixes the open "title not tracking" bug).

## Definition Of Done

- `AICoScientistKit` has a generic, `@Observable` Redux core (State, Action,
  Reducer, Store with sync + async dispatch, async Middleware), unit-tested.
- Run + download live state is a reduced `RunState`; the sparkline/graph/
  charts/activity + download progress render from it; **download progress is
  byte-reactive** (verified on a real download).
- Settings + study selection/editing flow through actions; UserDefaults +
  SwiftData persistence happen in middleware; the title-tracks-goal logic is
  a tested reducer (sidebar no longer shows stale "Untitled study").
- Reducers are **test-first** (mock backend, no GPU); middleware side-effects
  call the existing adapters only.
- No behavior regression: studies list/select/edit/run/results/settings work
  on macOS + iOS (build-verified + manual smoke).
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M22 tracking + closeout docs land with the final commit.

## Non-Goals

- Replacing SwiftData/CloudKit persistence — the store complements it.
- A third-party Redux dependency — port the operator's own pattern.
- Time-travel/devtools UI (a possible later milestone).
- New features — this is an architecture refactor; visuals/behavior parity.

## Open Questions

- **[?]** Store granularity: one root `AppState` + slice reducers, vs
  separate stores (RunStore/SettingsStore) sharing the core. Lean: one root
  store with slice reducers for a single source of truth.
- **[?]** Study read model: keep `@Query` for the list and hold only
  selection/editing in state, vs load studies into state via an action.
  Lean: keep `@Query` for the list (its CloudKit reactivity is valuable),
  put selection/editing/run in the store — resolve at delivery.
- **[?]** Byte-level progress source: whether the HF downloader exposes a
  byte stream or only per-file; if per-file only, interpolate. Resolve when
  wiring Track B.

## Risk

- **Big-bang refactor.** Migrating run + settings + study at once risks
  regressions. Mitigation: land Track A first (pure, additive), then migrate
  one slice per track behind small commits, keeping both apps green at each
  step; parity smoke-test before closeout.
- **SwiftData ↔ Redux impedance.** `@Query`/`@Model` reactivity vs a store.
  Mitigation: SwiftData stays the persistence/read model; the store holds
  app/run/selection state; writes via middleware.
- **Concurrency.** Swift 6 `@Sendable`/actor isolation for async middleware
  + progress callbacks. Mitigation: `@MainActor` store; `Sendable` actions.

## Scope Class

Large. New Kit subsystem + migration of three state areas across the app.
Recommend landing Track A, then B, C, D as separate review-able chunks
within the milestone. Estimated ~12–20 commits.
