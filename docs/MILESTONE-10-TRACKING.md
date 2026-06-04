# Milestone 10 Tracking

Date: 2026-06-04

Milestone:

```txt
Apple Foundation Models backend
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
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Package builds with the framework present; gated code compiles out where `canImport(FoundationModels)` is false. | Pending | Track B |
| `InferenceBackend.resolve` returns `.foundation` only when available, `.mlx` otherwise. | Pending | Track A |
| `FoundationModelsBackend.makeModel()` returns nil when unavailable / a model when available; consistent with `isAvailable`. | Pending | Track B |
| `--backend foundation` uses FM where available, else clear fallback to MLX; `--backend mlx` default unchanged. | Pending | Track C |
| MLX remains the default; no path makes Foundation Models required. | Pending | Track A/C |
| New behaviour is driven by a test written first (mock backend, no GPU). | Pending | all tracks |
| `import MLX*` adapter-only; `import FoundationModels` only under its target. | Pending | `git grep` check |

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
| FM ships as a `LanguageModel` backend; tools via the M6 loop. | Accepted | Same capability; avoids the high-risk dynamic-schema FM `Tool` bridge. |
| New gated target `AICoScientistFoundationModels`. | Accepted | Quarantines `import FoundationModels`; keeps the dependency optional. |
| `makeModel() -> (any LanguageModel)?` factory. | Accepted | CLI/app select FM without their own `canImport`/`@available` gates. |
