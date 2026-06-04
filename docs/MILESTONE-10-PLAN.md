# Milestone 10 Plan

Date: 2026-06-04

Working name:

```txt
Apple Foundation Models backend
```

## Status

Ready. Promoted from `docs/MILESTONE-10-PLANNING-DRAFT.md`.

## Goal

Add Apple's Foundation Models framework as an optional on-device backend
that conforms to our `LanguageModel` seam, selectable from the CLI and the
app on Apple-Intelligence devices (macOS/iOS 26+). MLX stays the default;
the whole backend is availability-gated so non-AI devices and toolchains
without the framework are unaffected. Tools work via M6's `GroundedDecoder`
loop over the FM backend (no native-`Tool` bridge required).

## Design (resolved open questions)

- **New gated target `AICoScientistFoundationModels`** (sibling to
  `AICoScientistMLX`): `import FoundationModels` lives only here, behind
  `#if canImport(FoundationModels)` + `@available(macOS 26, iOS 26, *)`,
  so the package builds where the framework is absent.
- **FM as a `LanguageModel`:** `FoundationLanguageModel.generateText`
  wraps `LanguageModelSession(instructions: system).respond(to: user)`
  (confirmed API: `Response<String>.content`,
  `GenerationOptions(temperature:maximumResponseTokens:)`).
- **Tools via M6, not native FM `Tool`:** the same end-user capability
  (FM agents calling research tools) is delivered by routing the FM
  backend through `GroundedDecoder`. The dynamic-schema `AgentTool` →
  FM `Tool` bridge is deferred (high-risk, low marginal value) — Non-Goal.
- **Selection seam:** a pure `InferenceBackend` resolver in Kit picks FM
  only when available, else falls back to MLX (local-first). A
  `FoundationModelsBackend.makeModel()` factory returns
  `(any LanguageModel)?` so the CLI/app need no `canImport` gates.

## Primary Scope (Execution Order)

Pure resolver first (device-independent, tested), then the gated adapter,
then selection surfaces.

### Track A — Backend selection model (AICoScientistKit)

`InferenceBackend` (`.mlx` / `.foundation`) + `resolve(requested:
foundationAvailable:)` → effective backend (foundation only if available,
else mlx). Pure, MLX-free, unit-tested.

### Track B — Foundation Models adapter (new target AICoScientistFoundationModels)

`FoundationLanguageModel: LanguageModel` over `LanguageModelSession`,
gated by `canImport` + `@available`. `FoundationModelsBackend.isAvailable`
(maps `SystemLanguageModel.default.availability`) and `makeModel()`
returning `(any LanguageModel)?`. Compiles with and without the framework.

### Track C — Selection surfaces (AICoScientistCLI + Apps/macOS)

CLI `--backend mlx|foundation` (default `mlx`): when `foundation` resolves
available, the generator is the FM model (embedder stays MLX); otherwise a
clear fallback to MLX. App: a backend picker in Settings, gated by
availability; `WorkflowRunner` builds the generator accordingly.

## Definition Of Done

- The package builds on this macOS 26 toolchain (framework present) and is
  written so the gated code compiles out where `canImport(FoundationModels)`
  is false.
- `InferenceBackend.resolve` returns `.foundation` only when available and
  `.mlx` otherwise (incl. `requested: .foundation, available: false` →
  `.mlx`), unit-tested.
- `FoundationModelsBackend.makeModel()` returns nil when unavailable and a
  `LanguageModel` when available; `isAvailable` is consistent with it,
  unit-tested (no device assertion on the boolean's value).
- `--backend foundation` uses the FM generator where available, else falls
  back to MLX with a clear message; `--backend mlx` (default) unchanged.
- MLX remains the default; no path makes Foundation Models required.
- Real FM inference is exercised only manually / opt-in, not in `swift test`.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green; macOS app builds.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`;
  `import FoundationModels` only under `Sources/AICoScientistFoundationModels/`.
- `git diff --check` clean.
- M10 tracking + closeout docs land with the final commit.

## Non-Goals

- Native FM `Tool` calling (dynamic `AgentTool` → FM `Tool` bridge) —
  deferred; tools work via the M6 `GroundedDecoder` loop over FM.
- FM guided generation / `@Generable` structured output — route FM through
  the existing `SchemaConstrainedDecoder` (one code path).
- Replacing the MLX path or FM-based embeddings — MLX stays default and
  owns embeddings.
- iOS backend-selection UI beyond what falls out for free.
