# Milestone 11 Closeout

Date: 2026-06-05

Milestone:

```txt
Batched reflection — review the pool in one call
```

## Status

Complete.

## Delivered

### Track A — Batched reflection agent (AICoScientistKit/Agents)

- `BatchReflectionAgent` + `BatchReviews`
  (`Sources/AICoScientistKit/Agents/BatchReflectionAgent.swift`): one
  structured decode reviews the whole hypothesis pool, returning a
  `HypothesisReview` per input hypothesis in order. `BatchReviews` is
  `Schematized` (array of the existing review schema). Pure, mock-tested.

### Track B — Engine uses the batched agent (AICoScientistKit/Engine)

- `reflectionPhase` now makes **one** decode per phase (was O(N)),
  assigning reviews positionally, setting each `score`, and counting
  reviews applied. Short returns are tolerated (apply what aligns, record
  one error); never crashes. Progress is a batched step ("reviewing N" →
  "reviewed k/N"). Reflection still routes through
  `router.decoder(for: .reflection)`, so M6 tool grounding still applies.
- Engine-test mocks return the batched shape; the per-role call-count
  assertion dropped 7→6 (reflection is now one call), `reviewsCount`
  unchanged at 3 (reviews *applied*), and the progress test asserts the
  batched shape.

## Scope change

This milestone was **re-scoped** from the drafted "KV/prompt-cache reuse +
quant tiers." Grinding the original showed both were low-ROI against the
code: `ChatSession` prefix caching is disk-based (no payoff for short
agent prompts; in-memory snapshots risk incoherent output per Apple's API
warning), and the catalog already exposes size tiers via the model picker.
The operator re-scoped to batched reflection — the genuine, testable,
backend-agnostic win.

## Validation

```txt
swift build                          # clean on Apple Silicon
swift test                           # 137 tests / 31 suites green (+3)
git grep "import MLX" -- '*.swift'   # only the MLX target (+ Package.swift comment)
git diff --check                     # whitespace clean
```

The speedup is structural (O(N)→1 reflection decode per phase) and applies
to every backend — MLX, Foundation Models, and hosted judges — and for
hosted judges it also cuts per-review API cost. A wall-clock figure would
come from an opt-in real-model run (not part of `swift test`).

## Retrospective

What worked:

- Grinding before committing scope caught two low-value sub-features and
  redirected M11 to a real win — the milestone-loop "a draft earns its
  place only if it traces to real value" check doing its job.
- Batching as one agent + a one-line engine swap kept the change small and
  fully unit-testable; `reviewsCount` semantics (reviews applied) stayed
  stable, so only call-count and progress assertions moved.
- Reusing the existing `HypothesisReview` schema made `BatchReviews`
  trivial and consistent with the per-item path.

What to improve:

- Batched review quality per hypothesis may be slightly lower than
  per-item (one prompt covers all); acceptable for the speed/cost win, but
  worth an eval if quality regresses.
- Tournament is still O(rounds × pairs) calls — a future batching target,
  though pairwise structure makes it harder.
- No automated wall-clock benchmark (needs a real model); only the
  structural call-count reduction is asserted.

Carry forward:

- Optional GPU memory-limit setting for stability on smaller Macs.
- Tournament/round batching if profiling shows it dominates.
- The M6–M11 batch is complete — run `milestone-planner` to scope the
  next arc (e.g. parity-test harness, native FM tool calling, iOS parity).
