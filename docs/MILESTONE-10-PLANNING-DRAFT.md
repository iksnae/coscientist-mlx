# Milestone 10 Planning Draft

Date: 2026-06-04

Working name:

```txt
Inference optimization — prompt-cache reuse + quant tiers
```

## Status

Draft. Not yet promoted to MILESTONE-10-PLAN.md.

## Goal

Pull the performance levers now that workflow parity holds. Reuse the
constant per-agent system-prompt prefix across decode calls (KV/prompt
cache) instead of re-encoding it every time, and expose quantization
tiers from the model catalog so a user can trade speed/memory for quality.
Success: a measurable wall-clock reduction on a real run, with the
optimization logic factored behind testable seams and the default
behavior unchanged in correctness.

## Context

The roadmap's "Optimization (orig. M7)" theme: *batched inference,
prefix/KV cache reuse, quant tiers — performance levers now that parity
holds.* Every agent has a constant `systemPrompt` (`Agent` protocol),
re-sent on each decode; the MLX adapter
(`Sources/AICoScientistMLX/MLXLanguageModel.swift`) currently does no
prefix reuse. The catalog (`ModelCatalog`) already carries size/RAM
metadata but exposes a single revision per model, not selectable quant
tiers. This milestone is MLX-adapter-local plus a small catalog/config
extension — it touches no agent logic and no engine shape.

## Usage Scenarios

### Scenario 1: Faster repeated decodes

Expected behavior:

- Within a run, decodes that share an agent's system-prompt prefix reuse
  a cached prefix rather than re-encoding it.
- A real-model run reports lower total time than the pre-change baseline,
  with identical hypothesis structure (correctness unchanged).

### Scenario 2: Choose a quant tier

Expected behavior:

- `swift run aicoscientist --list-models` shows available quant tiers per
  model; `--model <key>@<tier>` (or a tier flag) selects one.
- The app's model picker offers the tiers; a smaller tier loads faster /
  uses less RAM, surfaced via the existing size/RAM metadata.

## Primary Scope

### Track A — Prompt/KV cache reuse (AICoScientistMLX)

Add prefix-cache reuse keyed on the constant system prompt in the MLX
decode path, so the per-agent prefix is encoded once and reused across
that agent's calls within a run. The cache-management logic (key
derivation, lifetime, eviction) is factored so it is unit-testable
without a GPU; the actual MLX wiring stays inside the adapter.

### Track B — Quant tiers (AICoScientistKit catalog + surfaces)

Extend `CatalogModel` to carry selectable quant tiers (each a pinned
revision) and a resolver `key@tier → repo/revision`. Pure, mock-tested.
Surface tier selection in the CLI (`--list-models` output + selection)
and the app model picker.

### Track C — Benchmark harness (opt-in)

A small opt-in benchmark (integration target, not default `swift test`)
that runs a fixed goal and reports total time, so the speedup is
measured, not asserted in a flaky unit test.

## Definition Of Done

- The cache-key/lifetime logic is unit-tested (pure, no GPU): the same
  system prefix yields a cache hit; a different prefix does not.
- The MLX decode path reuses the cached prefix within a run; correctness
  of decoded output is unchanged vs. the no-cache path (mock seam +
  opt-in real run).
- `CatalogModel` resolves `key@tier` to a pinned repo/revision; unknown
  tiers fall back to the default with a clear error (unit-tested).
- CLI and app expose quant-tier selection; `--list-models` shows tiers.
- The opt-in benchmark reports a baseline and post-change total time
  (numbers recorded in the closeout, not asserted as a unit test).
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M10 tracking + closeout docs land with the final commit.

## Non-Goals

- Batched multi-hypothesis generation in one forward pass — a larger,
  separate optimization; defer unless cache reuse underdelivers.
- Cross-run/persistent cache on disk — in-run reuse only.
- Changing default models or revisions — tiers are additive; the current
  default stays the default.
- Quality benchmarking of quant tiers — we expose tiers; evaluating their
  quality belongs to the parity-test-harness theme.

## Open Questions

- **Cache invalidation granularity.** Per-agent-prefix is the safe,
  high-value case; finer-grained shared-prefix reuse across agents risks
  subtle correctness bugs. Lean per-agent prefix only.
- **Tier syntax.** `key@tier` vs. a separate `--quant` flag. Lean
  `key@tier` so one identifier carries the full selection (mirrors the
  catalog key). Delivery detail.

## Risk

- **Perf is hard to TDD.** Mitigate by unit-testing the pure cache-
  management logic and the tier resolver, and measuring real speedup in
  the opt-in benchmark (Track C) rather than a flaky timing assertion.
- **Cache reuse silently changing output.** Mitigate by asserting decoded
  output equality between cached and non-cached paths on the mock seam,
  and an opt-in real-run spot check in the closeout.

## Scope Class

Small-to-Medium. Track A's MLX cache wiring carries the only real
complexity; the catalog tiers and surfaces are thin and reuse existing
seams. Kept grindable by isolating cache logic behind a testable seam.

Estimated 4–5 commits (Track A) + 2–3 (Track B) + 1–2 (Track C),
~7–10 commits.
