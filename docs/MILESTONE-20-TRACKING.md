# Milestone 20 Tracking

Date: 2026-06-05

Milestone:

```txt
Provider model loading + Settings state cleanup
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
| Scope class | Small–Medium |
| Confidence | High |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Hosted models appear in the Study pickers on a fresh launch with a provider configured (no manual refresh). | Pending | |
| The configured model is always offered pre-fetch; the cached list survives relaunch. | Pending | |
| `SettingsStore` no longer declares `backend`, `agentModels`, `roleBackends`, presets, `generatorKey`, `remoteEnabled`; their UserDefaults keys are cleared on launch. | Pending | |
| `downloadPlan(for:)` uses `study.generator`. | Pending | |
| New logic is test-first (mock, no GPU); the pure `HostedModels` resolver is unit-tested. | Pending | |
| `swift build` clean; `swift test` green; macOS + iOS apps build. | Pending | |
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
| Pure `HostedModels` resolver in the Kit. | Accepted | UI-free + mock-testable; the picker calls it. |
| Cache fetched models in UserDefaults; background auto-refresh. | Accepted | Pickers populate at launch without a manual refresh. |
| Drop `remoteEnabled`; ready = base URL + key + model present. | Accepted | Removes a redundant gate/state. |
| Delete dead fields + clear their UserDefaults keys. | Accepted | Reference scan confirmed no live readers. |
