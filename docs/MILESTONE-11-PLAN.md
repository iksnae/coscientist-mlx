# Milestone 11 Plan

Date: 2026-06-05

Working name:

```txt
Batched reflection — review the pool in one call
```

## Status

Ready. Promoted from `docs/MILESTONE-11-PLANNING-DRAFT.md` (re-scoped from
"KV-cache reuse + quant tiers" on 2026-06-05 — see Context).

## Goal

Cut the reflection phase from **one model call per hypothesis** to **one
call for the whole pool**. Reflection is currently O(N) sequential decodes
(`for i in hypotheses.indices`); batching reviews the entire pool in a
single structured call. A real, backend-agnostic speed + API-cost
reduction (helps MLX, Foundation Models, and hosted judges alike), and
fully unit-testable with the mock backend.

## Context

Grinding the original M11 (KV/prompt-cache reuse + quant tiers) showed
both were low-ROI against the code: `ChatSession` prefix caching is
disk-based and wouldn't pay off for the short agent system prompts here
(and in-memory snapshots risk incoherent output per Apple's API warning),
while the catalog already exposes size tiers (`qwen3-1.7b/4b/8b`,
`llama3.2-1b/3b`) via the model picker. The operator re-scoped M11 to
**batched reflection**, the genuinely valuable optimization
(2026-06-05). Reflection is the clearest O(N)→O(1) win and is
provider-agnostic.

## Primary Scope (Execution Order)

### Track A — Batched reflection agent (AICoScientistKit/Agents)

`BatchReflectionAgent` (Agent) with input `{researchGoal, hypotheses:
[String]}` and `Schematized` output `BatchReviews {reviews:
[HypothesisReview]}` (array aligned to input order). Reuses the existing
`HypothesisReview` schema. Pure, MLX-free, unit-tested: N hypotheses in →
N reviews out from one decode.

### Track B — Engine uses the batched agent (AICoScientistKit/Engine)

`reflectionPhase` calls `BatchReflectionAgent` once via
`router.decoder(for: .reflection)`, assigns `reviews[i] → hypotheses[i]`
(positionally), sets each `score` from `scores.overall`, and increments
`reviewsCount` per applied review. Tolerant: if the model returns fewer
reviews than the pool, apply what aligns and record one error. Progress is
emitted as a batched step (start "reviewing N" + end "reviewed k/N")
rather than per-review. Engine tests updated (mock returns the batched
shape; reflection-call count and progress assertions adjusted).

## Definition Of Done

- `BatchReflectionAgent` returns one `HypothesisReview` per input
  hypothesis from a single decode (mock backend), unit-tested.
- `BatchReviews` is `Schematized` (array of the existing review schema)
  and decodes a `{"reviews":[…]}` payload, tested.
- The engine's reflection phase performs **one** decode per phase (not N);
  `reviewsCount` still equals the number of reviews applied, and each
  reviewed hypothesis gets its `score`. Verified via the per-role routing
  call-count test and the metrics test.
- A short/empty review array is tolerated (apply what aligns, record an
  error), never crashes the run.
- M6 grounding still applies (reflection routes through its role decoder).
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M11 tracking + closeout docs land with the final commit.

## Non-Goals

- KV/prompt-cache reuse and quant `key@tier` selection — investigated and
  dropped as low-ROI (see Context); existing model-size choices + M7
  hosted backing already cover the speed/memory tradeoff.
- Batching tournament (pairwise, harder) or other phases — reflection is
  the clean win; revisit others only if warranted.
- A GPU memory-limit setting — possible later stability tweak, out of scope.
- Removing the per-item `ReflectionAgent` — kept for single-hypothesis use.
