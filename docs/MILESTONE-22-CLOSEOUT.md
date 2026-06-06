# Milestone 22 Closeout

Date: 2026-06-05

Milestone:

```txt
Unidirectional state (Redux) — store, reducers, middleware; migrate run + settings + study
```

## Status

Delivered (code + tests). Live behavior verification on a device is
operator-pending — this milestone was built and unit-tested but not run live.

## Delivered

### Track A — Redux core (AICoScientistKit)

- `StateType`/`ActionType` markers, a pure closure `Reduce`, an `@Observable`
  `@MainActor` `Store` with sync + async `dispatch`, and async `Middleware`
  (the side-effects seam the operator's post left open). Built on the
  Observation framework. Unit-tested (`StoreTests`). Ported from
  https://iksnae.com/2022/12/04/swift-redux-protocols/.

### Track B — Run + download → `RunState`

- `RunState`/`RunAction`/`runReducer` + `EloTimelinePoint` (Kit, unit-tested:
  started resets, progress appends activity + Elo timeline and caps the log,
  finished/cleared). `WorkflowRunner` now holds one `RunState`, mutated only
  via the reducer; it dispatches `.started/.progress/.downloadProgress/
  .finished/.cleared` and projects the same accessor names, so the views
  (`RunProgressView`, `ActivityFeedView`, `ChartsView`, `GraphView`) are
  unchanged. Side-effects (model load, engine, thermal cancel) stay in the
  orchestrator.

### Track C — Settings → `SettingsState`

- `SettingsState`/`settingsReducer` + `remoteReady`/`hostedModelOptions`
  (Kit, unit-tested: key/baseURL change invalidates the model cache, model
  change doesn't, readiness, hosted-options delegation). `SettingsStore`
  projects it; setters dispatch through the reducer and run the side-effects
  (UserDefaults persistence, HF env). Binding/accessor names unchanged.

### Track D — Study title → `StudyTitle`

- `StudyTitle` (Kit, unit-tested): `isCustom` (empty/whitespace → not custom,
  resumes goal-tracking) + `display` (title, else goal's first line, else
  "Untitled study"). Wired into `StudyDetailView` (title onChange) +
  `StudiesView` (row + rename). **Fixes the stuck "Untitled study" bug** (a
  cleared title is no longer treated as a permanent custom title). SwiftData
  stays the persistence/read model (`@Query`) per the plan.

## Validation

```txt
swift build               # clean
swift test                # 177 tests / 43 suites green (+14 across A–D)
xcodebuild … both apps    # macOS + iOS BUILD SUCCEEDED
git grep "import MLX"     # only AICoScientistMLX/
git diff --check          # clean
```

## Retrospective

What worked:

- Pure reducers per area (run/settings/title) are unit-tested with the mock
  backend — the regression-prone state logic is now covered, fitting the TDD
  foundation.
- Keeping the existing `@Observable` stores as the host (projecting reduced
  state via same-named accessors) made the migration **view-invisible** —
  zero churn in the SwiftUI views, low regression risk.

What to improve / deviations (honest):

- **Pragmatic hosting.** Run/settings reducers are hosted in
  `WorkflowRunner`/`SettingsStore` rather than swapping the generic `Store`
  in everywhere. This was a deliberate risk/reward call (Observation
  reliability + no view rewrite, since I can't run the app live here). The
  generic `Store` + `Middleware` (Track A) is available + tested for new
  state and a future deeper migration.
- **Study selection** stays in SwiftUI `@State`/`@Query` (SwiftData read
  model), per the plan's resolved decision — not routed through the store.
- **Download progress granularity** is still what the HF downloader reports
  (per-file); it now flows through `RunAction.downloadProgress` consistently,
  but true byte-streaming is library-limited.
- **Live verification pending:** built + unit-tested only. The operator
  should smoke-test run/results/settings/list on device.

Carry forward:

- Operator: live smoke test of M22 on device.
- A future milestone could move run/settings onto the generic `Store` +
  middleware and route study selection through it if desired.
- **M19 — LAN model offload** remains the next drafted milestone.
