# Milestone 10 Closeout

Date: 2026-06-04

Milestone:

```txt
Apple Foundation Models backend
```

## Status

Complete.

## Delivered

### Track A — Backend selection seam (AICoScientistKit)

- `InferenceBackend` (`.mlx` / `.foundation`) +
  `resolve(requested:foundationAvailable:)`
  (`Sources/AICoScientistKit/Inference/InferenceBackend.swift`): picks
  Foundation Models only when available, else falls back to MLX
  (local-first). Pure, MLX-free, unit-tested.

### Track B — Foundation Models adapter (new target AICoScientistFoundationModels)

- `FoundationLanguageModel: LanguageModel` over `LanguageModelSession`
  (`respond(to:options:)`), behind `#if canImport(FoundationModels)` +
  `@available(macOS 26, iOS 26, *)` so the package still builds where the
  framework is absent.
- `FoundationModelsBackend.isAvailable` (maps
  `SystemLanguageModel.default.availability`) and `makeModel() -> (any
  LanguageModel)?`, so callers select FM without their own gates.
- `import FoundationModels` is quarantined to this target.

### Track C — Backend selection surfaces (AICoScientistCLI + Apps/macOS)

- CLI `--backend mlx|foundation` (default `mlx`): a shared
  `loadGenerator()` uses the FM generator when resolved-available, else a
  clear MLX fallback (embedder stays MLX).
- App: `SettingsStore.backend` (persisted) + `foundationAvailable`; a
  backend picker in Settings ▸ Models; `WorkflowRunner` builds the FM
  generator when selected/available. `project.yml` links the FM product.

Tools work over FM via the M6 `GroundedDecoder` loop — no native FM
`Tool` bridge in this milestone (see Non-Goals).

## Validation

```txt
swift build                          # clean on macOS 26 (FM present)
swift test                           # 134 tests / 30 suites green (+3)
xcodebuild … -scheme CoScientistDemo # macOS app BUILD SUCCEEDED
git grep "import FoundationModels"   # only the FM target (+ Package.swift comment)
git grep "import MLX" -- '*.swift'   # only the MLX target (+ Package.swift comment)
git diff --check                     # whitespace clean
```

Real Foundation Models inference is exercised manually / opt-in (it needs
Apple Intelligence enabled on the device), never in the default
`swift test` path. The `FoundationModelsBackendTests` assert
`makeModel()`/`isAvailable` consistency without depending on a device.

## Retrospective

What worked:

- The `LanguageModel` seam meant FM dropped in as just another backend —
  no engine/agent change — and the pure `InferenceBackend.resolve` made
  selection + fallback fully unit-testable on any device.
- Scoping FM as a text backend (tools via the M6 loop) avoided the
  high-risk dynamic-schema `AgentTool` → FM `Tool` bridge while still
  giving FM agents tool access. The real FM API matched the plan
  (`LanguageModelSession` / `respond` / `availability`).
- `makeModel() -> (any LanguageModel)?` kept all `canImport`/`@available`
  gating inside the FM target; the CLI and app stayed gate-free.

What to improve:

- Native FM tool calling (the `@Generable`/`GenerationSchema` `Tool`
  bridge) is deferred — would let FM call tools through Apple's runtime
  rather than our text loop (carry-forward).
- FM generation isn't covered by an automated end-to-end test (device +
  Apple Intelligence required); only the seams are unit-tested.
- App backend selection is global (Settings), not per-study; per-study
  backend could pair with M7's per-agent backing.

Carry forward (M11 candidates):

- M11 — Inference optimization (prompt/KV cache reuse + quant tiers;
  drafted).
- Native FM `Tool` bridge for first-class FM tool calling.
- Per-study / per-agent backend selection (compose with M7).
