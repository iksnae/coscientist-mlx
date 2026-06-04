# Milestone 8 Plan

Date: 2026-06-04

Working name:

```txt
Apple Foundation Models backend (native tool calling)
```

## Status

Ready. Promoted from `docs/MILESTONE-8-PLANNING-DRAFT.md`.

## Goal

Add Apple's Foundation Models framework as an optional on-device backend
that conforms to our `LanguageModel` seam and maps `AgentTool` to its
native `Tool` calling. On an Apple-Intelligence device (OS 26+), agents
can run on Apple's native stack with first-class tool calls — typically
more reliable than M6's text-convention loop on small open models — while
MLX stays the default and the backend is availability-gated so non-AI
devices and CI are unaffected.

## Design (resolved open questions)

- **New gated target `AICoScientistFoundationModels`** (sibling to
  `AICoScientistMLX`), so the `import FoundationModels` is quarantined and
  the dependency stays optional — mirrors the MLX rule.
- **Structured output routes through our existing `SchemaConstrainedDecoder`**
  (one code path); FM guided-generation is a possible later optimization,
  not this milestone.
- **Composes with M6/M7:** the adapter is just another `LanguageModel`, so
  `RoleDecoderRouter`/`GroundedDecoder` can already route a role to it.

## Primary Scope (Execution Order)

Pure mapping first (testable without a device), then the gated adapter,
then selection.

### Track A — AgentTool → native Tool mapping (AICoScientistFoundationModels)

A pure adapter that maps an `AgentTool` (name, description, `JSONSchema`,
`call`) to the shape Foundation Models' `Tool` expects, with the
result round-trip. Unit-tested through a protocol seam/mock — **no device
dependency** — so name/description/schema/result are asserted in CI.

### Track B — Foundation Models LanguageModel adapter (same target)

A `LanguageModel` conformance over `LanguageModelSession`, compiled behind
`#if canImport(FoundationModels)` + `@available` gates so the package
still builds where the framework is absent. Real inference is exercised
only in an opt-in integration path, never the default `swift test`.

### Track C — Backend selection (AICoScientistCLI + Apps/macOS)

A `--backend mlx|foundation` flag (default `mlx`) and an availability-gated
entry in the app's backend/model picker. Selection constructs the
appropriate decoder; engine and agents are unchanged.

## Definition Of Done

- The package builds on a toolchain *without* Foundation Models (gates
  compile it out) and on one *with* it.
- The `AgentTool` → native `Tool` mapping is unit-tested via a seam/mock
  (no device): name, description, schema, and result round-trip asserted.
- `--backend foundation` selects the adapter where available and is a
  clean no-op/hidden where not; `--backend mlx` (default) is unchanged.
- MLX remains the default; no path makes Foundation Models required
  (local-first, device-agnostic).
- Real Foundation Models inference lives only in an opt-in integration
  path, not the default `swift test`.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M8 tracking + closeout docs land with the final commit.

## Non-Goals

- Replacing the MLX path — FM is a fixed ~3B Apple model; MLX runs any
  open model and stays default.
- iOS backend-selection UI beyond what falls out for free.
- FM guided-generation rework — adapt through the existing decoder.
