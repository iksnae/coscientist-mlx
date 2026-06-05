# Milestone 20 Tracking

Date: 2026-06-05

Milestone:

```txt
Provider model loading + Settings state cleanup
```

## Status

Complete

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | 2026-06-05 |
| Elapsed | same day |
| Scope class | Small–Medium |
| Confidence | High |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Hosted models appear in the Study pickers on a fresh launch with a provider configured (no manual refresh). | Done | `ModelChoicePicker` `.task { ensureModelsLoaded() }` + `hostedModelOptions`; both apps build. |
| The configured model is always offered pre-fetch; the cached list survives relaunch. | Done | `HostedModels.options` includes configured model; `fetchedModels` persisted to UserDefaults. |
| `SettingsStore` no longer declares `backend`, `agentModels`, `roleBackends`, presets, `generatorKey`, `remoteEnabled`; their UserDefaults keys are cleared on launch. | Done | Rewritten `SettingsStore`; `migrateRemovingDeadKeys()`. |
| `downloadPlan(for:)` uses `study.generator`. | Done | `WorkflowRunner.downloadPlan` evaluates the selected `ModelChoice`. |
| New logic is test-first (mock, no GPU); the pure `HostedModels` resolver is unit-tested. | Done | `HostedModelsTests` (5) written before impl. |
| `swift build` clean; `swift test` green; macOS + iOS apps build. | Done | 157 tests / 37 suites; both BUILD SUCCEEDED. |
| `import MLX*` only under `Sources/AICoScientistMLX/`. | Done | `git grep` → only the `Package.swift` comment. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean. |
| `swift test` | Passed | 157 tests / 37 suites (+5). |
| macOS app build | Passed | `CoScientistDemo` BUILD SUCCEEDED. |
| iOS app build | Passed | `CoScientistApp` BUILD SUCCEEDED. |
| `git diff --check` | Passed | Clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Pure `HostedModels` resolver in the Kit. | Accepted | UI-free + mock-testable; the picker calls it. |
| Cache fetched models in UserDefaults; background auto-refresh. | Accepted | Pickers populate at launch without a manual refresh. |
| Drop `remoteEnabled`; ready = base URL + key + model present. | Accepted | Removes a redundant gate/state. |
| Delete dead fields + clear their UserDefaults keys. | Accepted | Reference scan confirmed no live readers. |
