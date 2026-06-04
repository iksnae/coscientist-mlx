# Milestone 10 Tracking

Date: 2026-06-04

Milestone:

```txt
Apple Foundation Models backend
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
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Package builds with the framework present; gated code compiles out where `canImport(FoundationModels)` is false. | Done | `#if canImport`/`@available` gates (958e60d); `swift build` clean on macOS 26. |
| `InferenceBackend.resolve` returns `.foundation` only when available, `.mlx` otherwise. | Done | `InferenceBackendTests.resolve` (41184af) |
| `FoundationModelsBackend.makeModel()` returns nil when unavailable / a model when available; consistent with `isAvailable`. | Done | `FoundationModelsBackendTests.consistency` (958e60d) |
| `--backend foundation` uses FM where available, else clear fallback to MLX; `--backend mlx` default unchanged. | Done | CLI `loadGenerator` (034419c); `--help` shows values mlx, foundation |
| MLX remains the default; no path makes Foundation Models required. | Done | Default `.mlx`; resolver falls back to `.mlx`. |
| New behaviour is driven by a test written first (mock backend, no GPU). | Done | `InferenceBackendTests`, `FoundationModelsBackendTests` first. |
| `import MLX*` adapter-only; `import FoundationModels` only under its target. | Done | `git grep` → only `Package.swift` comments outside the two adapters. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on macOS 26 (FM framework present). |
| `swift test` | Passed | 134 tests / 30 suites green (+3). |
| macOS app build | Passed | `xcodebuild … CoScientistDemo` BUILD SUCCEEDED. |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| FM ships as a `LanguageModel` backend; tools via the M6 loop. | Accepted | Same capability; avoids the high-risk dynamic-schema FM `Tool` bridge. |
| New gated target `AICoScientistFoundationModels`. | Accepted | Quarantines `import FoundationModels`; keeps the dependency optional. |
| `makeModel() -> (any LanguageModel)?` factory. | Accepted | CLI/app select FM without their own `canImport`/`@available` gates. |
