# Milestone 11 Planning Draft

Date: 2026-06-04

Working name:

```txt
Inference optimization — prompt-cache reuse + quant tiers
```

## Status

Draft. Not yet promoted to MILESTONE-11-PLAN.md. (Renumbered from M10 when
the results-presentation UX was inserted ahead of it on 2026-06-04.)

## Goal

Pull the performance levers now that workflow parity holds. Reuse the
constant per-agent system-prompt prefix across decode calls (KV/prompt
cache) instead of re-encoding it every time, and expose quantization
tiers from the model catalog so a user can trade speed/memory for quality.
Success: a measurable wall-clock reduction on a real run, with the
optimization logic factored behind testable seams and default behavior
unchanged in correctness.

## Context

Roadmap theme "Optimization (orig. M7)": batched inference, prefix/KV
cache reuse, quant tiers. Every agent has a constant `systemPrompt`
(`Agent` protocol), re-sent each decode; the MLX adapter
(`Sources/AICoScientistMLX/MLXLanguageModel.swift`) does no prefix reuse.
`ModelCatalog` carries size/RAM metadata but a single revision per model,
not selectable quant tiers. MLX-adapter-local plus a small catalog/config
extension — no agent logic, no engine shape change.

## Usage Scenarios

### Scenario 1: Faster repeated decodes

Expected behavior:

- Decodes that share an agent's system-prompt prefix reuse a cached
  prefix rather than re-encoding it.
- A real-model run reports lower total time than the pre-change baseline,
  with identical hypothesis structure (correctness unchanged).

### Scenario 2: Choose a quant tier

Expected behavior:

- `--list-models` shows available quant tiers per model; `--model
  <key>@<tier>` selects one; the app picker offers the tiers.
- A smaller tier loads faster / uses less RAM, surfaced via existing
  size/RAM metadata.

## Primary Scope

### Track A — Prompt/KV cache reuse (AICoScientistMLX)

Prefix-cache reuse keyed on the constant system prompt in the MLX decode
path, so the per-agent prefix is encoded once and reused across that
agent's calls within a run. Cache-management logic (key, lifetime,
eviction) factored to be unit-testable without a GPU; the MLX wiring stays
in the adapter.

### Track B — Quant tiers (AICoScientistKit catalog + surfaces)

Extend `CatalogModel` with selectable quant tiers (each a pinned
revision) + a resolver `key@tier → repo/revision`. Pure, mock-tested.
Surface tier selection in the CLI + app picker.

### Track C — Benchmark harness (opt-in)

A small opt-in benchmark (integration, not default `swift test`) that runs
a fixed goal and reports total time, so the speedup is measured, not
asserted in a flaky unit test.

## Definition Of Done

- The cache-key/lifetime logic is unit-tested (pure, no GPU): same prefix
  → hit; different prefix → miss.
- The MLX decode path reuses the cached prefix within a run; decoded
  output is unchanged vs. the no-cache path (mock seam + opt-in real run).
- `CatalogModel` resolves `key@tier` to a pinned repo/revision; unknown
  tiers fall back to the default with a clear error (unit-tested).
- CLI + app expose quant-tier selection; `--list-models` shows tiers.
- The opt-in benchmark reports baseline vs. post-change total time
  (recorded in the closeout, not asserted as a unit test).
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M11 tracking + closeout docs land with the final commit.

## Non-Goals

- Batched multi-hypothesis generation in one forward pass — larger,
  separate; defer unless cache reuse underdelivers.
- Cross-run/persistent on-disk cache — in-run reuse only.
- Changing default models/revisions — tiers are additive.
- Quality benchmarking of quant tiers — belongs to the parity-harness theme.

## Open Questions

- **Cache invalidation granularity.** Per-agent-prefix is the safe,
  high-value case; finer cross-agent reuse risks subtle bugs. Lean
  per-agent prefix only.
- **Tier syntax.** `key@tier` vs. a separate `--quant` flag. Lean
  `key@tier`.

## Risk

- **Perf is hard to TDD.** Unit-test the pure cache-management + tier
  resolver; measure real speedup in the opt-in benchmark, not a flaky
  timing assertion.
- **Cache reuse silently changing output.** Assert decoded-output equality
  between cached and non-cached paths on the mock seam + an opt-in real
  spot check.

## Scope Class

Small-to-Medium. Track A's MLX cache wiring is the only real complexity;
catalog tiers + surfaces are thin. Kept grindable by isolating cache logic
behind a testable seam.

Estimated 4–5 commits (Track A) + 2–3 (Track B) + 1–2 (Track C),
~7–10 commits.
