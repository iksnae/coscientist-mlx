# Milestone 20 Closeout

Date: 2026-06-05

Milestone:

```txt
Provider model loading + Settings state cleanup
```

## Status

Complete.

## Delivered

### Track A — Auto-load + cache hosted models

- `HostedModels` (`Sources/AICoScientistKit/Inference/HostedModels.swift`): a
  pure resolver — `options(ready:configured:fetched:)` returns the hosted ids
  to offer, configured-model-first, de-duplicated, empty when not ready.
  Unit-tested (`HostedModelsTests`, 5 cases) before implementation.
- `SettingsStore`: `fetchedModels` is now **cached in UserDefaults** (survives
  relaunch); `ensureModelsLoaded()` background-loads the list once when the
  provider is ready and the cache is empty; `hostedModelOptions` exposes the
  resolver. `ModelChoicePicker` builds its Hosted section from
  `hostedModelOptions` and calls `ensureModelsLoaded()` from `.task` — so
  hosted models appear in the Study pickers on a fresh launch with **no manual
  Settings refresh**, and the configured model is always offered pre-fetch.

### Track B — Delete dead provider/model state

- Removed from `SettingsStore`: `backend`, `agentModels`, `roleBackends`,
  `applyPreset`/`BackingPreset`, `generatorKey` — all dead since the M13
  per-study `ModelChoice` + `StudyRouting` routing (reference scan confirmed
  no live readers). Their persisted UserDefaults keys are cleared on launch
  (`migrateRemovingDeadKeys`).
- Dropped `remoteEnabled`: a provider is "ready" when base URL + key + model
  are present. `SettingsView` lost the enable toggle and the `.disabled`
  gates; copy updated to say hosted models appear automatically.
- `WorkflowRunner.downloadPlan(for:)` now evaluates the actually-selected
  `study.generator` (on-device only; hosted downloads nothing) instead of the
  legacy `study.generatorKey`, so the disk guard checks the right model.

## Validation

```txt
swift build                       # clean
swift test                        # 157 tests / 37 suites green (+5)
xcodebuild … CoScientistDemo      # macOS BUILD SUCCEEDED
xcodebuild … CoScientistApp …iOS  # iOS BUILD SUCCEEDED
git grep "import MLX" -- '*.swift'  # only the Package.swift comment
git diff --check                  # clean
```

## Retrospective

What worked:

- Pulling the picker's "what to show" rule into a pure Kit resolver made the
  fix test-first and tiny; the UI just renders it.
- The reference scan before deleting gave confidence the dead fields had no
  readers — the compiler + both app builds confirmed it.
- Caching `fetchedModels` + a `.task` auto-load is a small change that removes
  a real point of confusion (hosted models silently missing).

What to improve:

- `study.generatorKey` (the SwiftData field) is now fully unused but kept to
  avoid a schema change; a later migration could drop it.
- Auto-refresh is once-per-provider; a periodic/stale refresh could be added
  if provider catalogs change often.

Carry forward:

- **M21 — Professional UI redesign** (next): the data now feeds the pickers
  correctly; M21 makes the surface read well (selected-model in pickers,
  non-duplicated conclusion, differentiated titles, plain status, hierarchy).
- Drop the unused `study.generatorKey` SwiftData field in a future schema pass.
- M19 (LAN offload) still parked.
