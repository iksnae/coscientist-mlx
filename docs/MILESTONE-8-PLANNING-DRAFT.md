# Milestone 8 Planning Draft

Date: 2026-06-04

Working name:

```txt
Apple Foundation Models backend (native tool calling)
```

## Status

Draft. Not yet promoted to MILESTONE-8-PLAN.md.

## Goal

Add Apple's Foundation Models framework as an optional on-device backend
that conforms to our `LanguageModel` seam and maps our `AgentTool`
protocol to its native `Tool` calling. On an Apple-Intelligence device
(OS 26+), agents can run on Apple's native stack with first-class tool
calls — typically more reliable than the text-convention loop M6 uses on
small open models — while the MLX path remains the default and the whole
backend is availability-gated so non-AI devices and CI are unaffected.

## Context

The agent-research arc named a Foundation Models backend as "Increment
4." Apple's Foundation Models framework (OS 26) provides an on-device LLM
via `LanguageModelSession`, guided generation, and a native `Tool`
protocol the model invokes mid-generation — a direct analogue of the seam
M6 builds. We already isolate adapters behind protocols
(`LanguageModel`, `SchemaConstrainedDecoding`), so Foundation Models slots
in as a sibling to `AICoScientistMLX` without touching the engine. The
`AgentTool` shape (PR #29) was deliberately designed so it can map to a
native `Tool` — this milestone cashes that in.

## Usage Scenarios

### Scenario 1: Select the Apple backend where available

Expected behavior:

- On a supported device, "Apple Foundation Models" is an offered backend
  in the CLI (`--backend foundation`) and the app's model picker.
- On an unsupported device/OS, the option is absent (gracefully hidden),
  and the MLX path remains the default — no crash, no error.

### Scenario 2: Native tool calling

Expected behavior:

- When tools are enabled (M6), the Foundation Models backend exposes them
  as native `Tool`s, so the model calls them through Apple's runtime
  rather than the text-convention loop.
- A scripted/mock seam verifies that an `AgentTool` is correctly adapted
  to the native tool shape and that results round-trip back.

## Primary Scope

### Track A — Foundation Models adapter (new target `AICoScientistFoundationModels`)

A new adapter target conforming `LanguageModel` (and the structured-decode
seam) over `LanguageModelSession`, compiled behind
`#if canImport(FoundationModels)` + `@available` gates so the package
still builds where the framework is absent. Keeps the import quarantined
to this target, mirroring the MLX rule. An `AgentTool` → native `Tool`
adapter maps name/description/`JSONSchema`/`call`.

### Track B — Backend selection (AICoScientistCLI + Apps/macOS)

A `--backend mlx|foundation` flag (default `mlx`) and an availability-
gated entry in the app's model/backend picker. Selection constructs the
appropriate decoder; everything downstream (engine, agents) is unchanged.

## Definition Of Done

- The package builds on a toolchain *without* Foundation Models (gates
  compile it out) and on one *with* it.
- The `AgentTool` → native `Tool` adapter is unit-tested via a protocol
  seam/mock (no device dependency): name, description, schema, and
  result round-trip are asserted.
- `--backend foundation` selects the adapter where available and is a
  clean no-op/hidden where not; `--backend mlx` (default) is unchanged.
- MLX remains the default backend; no path makes Foundation Models
  required (local-first, device-agnostic).
- Real Foundation Models inference is exercised only in an opt-in
  integration target (like the GPU runner), not the default `swift test`.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M8 tracking + closeout docs land with the final commit.

## Non-Goals

- Replacing the MLX path — Foundation Models is a fixed ~3B Apple model
  tied to Apple Intelligence; MLX runs any open model and stays default.
- iOS UI for backend selection beyond what falls out for free — focus is
  the adapter + macOS/CLI selection.
- Guided-generation parity rework — our schema-constrained decoder
  already covers structured output; we adapt, not re-architect.

## Open Questions

- **Module vs. file in MLX target.** A separate `AICoScientistFoundationModels`
  target keeps imports clean and the dependency optional; folding it into
  an existing target risks coupling. Lean a new target.
- **Structured output via FM.** Whether to use FM's guided generation or
  route FM text through our existing decoder. Lean our decoder first
  (one code path), revisit if FM guided-gen is materially better.

## Risk

- **CI toolchain lacks Foundation Models.** The whole point of the
  `canImport`/`@available` gates: the default build/test must pass with
  the framework absent. Verify in CI that the gated code compiles out.
- **API churn / device access for real validation.** Mitigate by keeping
  real-device runs in the opt-in integration target and unit-testing only
  the adapter mapping through a seam.

## Scope Class

Small. One gated adapter target + a thin selection flag; the engine and
agents are untouched. The availability gating is the only fiddly part.

Estimated 3–4 commits (Track A) + 2 (Track B), ~5–6 commits.
