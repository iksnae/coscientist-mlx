# Milestone 10 Planning Draft

Date: 2026-06-04

Working name:

```txt
Apple Foundation Models backend (native tool calling)
```

## Status

Draft. Not yet promoted to MILESTONE-10-PLAN.md. (Deferred from M8 when
the results-presentation UX was reprioritized ahead of it on 2026-06-04.)

## Goal

Add Apple's Foundation Models framework as an optional on-device backend
that conforms to our `LanguageModel` seam and maps `AgentTool` to its
native `Tool` calling. On an Apple-Intelligence device (OS 26+), agents
can run on Apple's native stack with first-class tool calls — typically
more reliable than M6's text-convention loop on small open models — while
MLX stays the default and the backend is availability-gated so non-AI
devices and CI are unaffected.

## Context

The agent-research arc named a Foundation Models backend as "Increment
4." Apple's Foundation Models framework (OS 26) provides an on-device LLM
via `LanguageModelSession`, guided generation, and a native `Tool`
protocol — a direct analogue of the M6 tool-use seam. Adapters are
already isolated behind protocols (`LanguageModel`,
`SchemaConstrainedDecoding`), so FM slots in beside `AICoScientistMLX`
without touching the engine, and M7's `RoleDecoderRouter` can already
route a role to it. The `AgentTool` shape (PR #29) was designed to map to
a native `Tool` — this milestone cashes that in.

## Usage Scenarios

### Scenario 1: Select the Apple backend where available

Expected behavior:

- On a supported device, "Apple Foundation Models" is an offered backend
  in the CLI (`--backend foundation`) and the app's picker.
- On an unsupported device/OS, the option is absent (gracefully hidden),
  and MLX remains the default — no crash, no error.

### Scenario 2: Native tool calling

Expected behavior:

- When tools are enabled (M6), the FM backend exposes them as native
  `Tool`s so the model calls them through Apple's runtime.
- A scripted/mock seam verifies an `AgentTool` adapts to the native tool
  shape and results round-trip.

## Primary Scope

### Track A — AgentTool → native Tool mapping (new target AICoScientistFoundationModels)

A pure adapter mapping `AgentTool` (name, description, `JSONSchema`,
`call`) to the Foundation Models `Tool` shape, with result round-trip.
Unit-tested via a seam/mock — no device dependency.

### Track B — Foundation Models LanguageModel adapter (same target)

A `LanguageModel` conformance over `LanguageModelSession`, compiled behind
`#if canImport(FoundationModels)` + `@available` gates so the package
still builds where the framework is absent. Structured output routes
through the existing `SchemaConstrainedDecoder` (one code path). Real
inference is opt-in integration only.

### Track C — Backend selection (AICoScientistCLI + Apps/macOS)

A `--backend mlx|foundation` flag (default `mlx`) and an availability-gated
picker entry; engine and agents unchanged.

## Definition Of Done

- The package builds on a toolchain without Foundation Models (gates
  compile it out) and with it.
- The `AgentTool` → native `Tool` mapping is unit-tested via a seam/mock
  (no device): name, description, schema, result round-trip asserted.
- `--backend foundation` selects the adapter where available, is hidden/
  no-op where not; `--backend mlx` (default) unchanged.
- MLX remains the default; no path makes Foundation Models required.
- Real FM inference lives only in an opt-in integration path.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M10 tracking + closeout docs land with the final commit.

## Non-Goals

- Replacing the MLX path — FM is a fixed ~3B Apple model; MLX stays default.
- iOS backend-selection UI beyond what falls out for free.
- FM guided-generation rework — adapt through the existing decoder.

## Open Questions

- **Structured output via FM.** Existing decoder first; revisit FM
  guided-gen if materially better. Lean existing decoder.

## Risk

- **CI toolchain lacks Foundation Models.** The `canImport`/`@available`
  gates must keep the default build/test green with the framework absent;
  verify in CI.
- **API churn / device access.** Keep real-device runs in the opt-in
  integration path; unit-test only the adapter mapping.

## Scope Class

Small. One gated adapter target + a thin selection flag; engine and agents
untouched. Availability gating is the only fiddly part.

Estimated 3–4 commits (Track A/B) + 2 (Track C), ~5–6 commits.
