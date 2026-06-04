# AI-CoScientist → Swift / MLX Port — Architecture & Plan

A native Swift port of AI-CoScientist targeting Apple Silicon, running local open
models via **MLX-Swift** (Metal-backed). Goal: feature-equivalent to the Python
reference, then superior where the local + native stack allows.

> **Origin & citation.** The methodology — a multi-agent "generate, debate, evolve"
> loop with Elo-tournament self-play over research hypotheses — is from Google's
> *Towards an AI co-scientist* (Gottweis et al., 2025, [arXiv:2502.18864](https://arxiv.org/abs/2502.18864)).
> The Python reference this port follows is
> [The-Swarm-Corporation/AI-CoScientist](https://github.com/The-Swarm-Corporation/AI-CoScientist)
> (MIT), built on the [Swarms](https://github.com/kyegomez/swarms) framework
> (Apache-2.0). Not to be confused with Sakana AI's *The AI Scientist*
> ([arXiv:2408.06292](https://arxiv.org/abs/2408.06292)), a separate system. Full
> references and citation live in the [README](../README.md#references).

Decisions locked in:
- **Form factor:** SPM library (`AICoScientistKit`) + CLI (`aicoscientist`). App can sit on top later.
- **Inference:** MLX-Swift + **schema-constrained decoding**, Codable-first (see §3).
- **Metal:** MLX's Metal backend only — no hand-written kernels. Embeddings/similarity ride MLX array ops.
- **Deliverable order:** this design doc first, then scaffold, then iterate.

---

## 1. What the Python reference actually does

One class, `AIScientistFramework` (`ai_coscientist/main.py`, ~2000 lines), orchestrating
8 single-shot `swarms.Agent` instances (LLM + system prompt, `max_loops=1`). Agents
communicate by returning JSON text, parsed best-effort by `_safely_parse_json`.

Pipeline (`run_research_workflow`):

```
generation → reflection → ranking → tournament
then for max_iterations:
    meta-review → evolution(top-k) → reflection → ranking → tournament → proximity
```

Key mechanics to preserve:
- **Hypothesis**: text, Elo (start 1200), reviews[], score 0–1, cluster id, evolution history, win/loss.
- **Elo**: standard expected-score update; tournament runs `3·N` random pairwise matches, an LLM judge picks the winner (`k_factor=24`).
- **Ranking**: order by review score, then re-order by Elo after tournament.
- **Proximity**: LLM returns similarity clusters; hypotheses matched back by **exact string equality** (fragile — see §6).
- **Supervisor agent**: initialized but never invoked. We drop it (or repurpose it as a real router).

Failure modes we inherit and must fix for local models:
- JSON validity is assumed; small models break it → constrained decoding (§3).
- String-equality cluster matching → stable IDs + embeddings (§6).

---

## 2. Package layout

```
Package.swift
Sources/
  AICoScientistKit/
    Core/          Hypothesis, ReviewScores, HypothesisReview, TournamentJudgment,
                   ProximityResult, WorkflowResult, ExecutionMetrics  (Codable, Sendable)
    Inference/     LanguageModel protocol, MLXLanguageModel, ModelActor,
                   StructuredSampler (schema-constrained), GenerationConfig
    Embeddings/    EmbeddingModel (MLX), Similarity (cosine, clustering)
    Agents/        Agent protocol + 7 concrete agents (Generation, Reflection,
                   Ranking, Evolution, MetaReview, Tournament, Proximity)
    Engine/        CoScientistEngine (orchestrator), Phases, Elo, StatePersistence
    Support/       Logging (swift-log), Prompts
  AICoScientistCLI/   main.swift (ArgumentParser) — mirrors example.py
Tests/
  AICoScientistKitTests/   Elo math, JSON-schema decode, clustering, parity fixtures
```

Dependencies (verified June 2026 — see `.claude/skills/mlx-swift`):
- `mlx-swift` ≥ 0.31.4 — core arrays/ops (`MLX`, `MLXNN`, `MLXLinalg`, …).
- `mlx-swift-lm` ≥ 3.31.3 — the LLM/embedding libraries (`MLXLLM`, `MLXLMCommon`,
  `MLXEmbedders`, `MLXHuggingFace`). NOTE: these **moved out of `mlx-swift-examples`**;
  do not depend on the examples repo for library code.
- `swift-json-schema` (`@Schemable`: Codable→schema) + `mlx-swift-structured` (XGrammar
  constrained decoding) for structured output — both behind the `StructuredDecoder` protocol.
- `swift-argument-parser`, `swift-log`.

Min platform: macOS 14 (Apple Silicon only). MLX deps are introduced at M1; M0 is a
pure-Swift, MLX-free, fully-tested skeleton (mock backend) per TDD.

---

## 3. Inference & structured output (the crux)

**`LanguageModel` protocol** abstracts generation so the engine never touches MLX directly:

```swift
protocol LanguageModel: Sendable {
    func generate<T: Decodable>(_ type: T.Type, system: String, user: String,
                                config: GenerationConfig) async throws -> T
    func generateText(system: String, user: String,
                      config: GenerationConfig) async throws -> String
}
```

`MLXLanguageModel` is the concrete impl. **`MLXArray` is not `Sendable`** (verified) —
arrays cannot cross isolation boundaries under Swift 6, so all array work stays inside the
library's `ModelContainer.perform { … }` and only `Sendable` values escape. The model
lives behind a **`ModelActor`** that serializes GPU access (MLX evaluation is internally
lock-serialized, so one resident model + one actor is correct, not limiting). Agents are
`async` and fan out logically; inference funnels through the actor, with **batching** —
not threads — as the throughput escape hatch (§7).

**Structured output — `StructuredSampler`.** Every agent output is a `Codable` struct.
We derive a JSON grammar from the schema and install a `LogitProcessor` that masks tokens
to only those that keep the output a valid prefix of the schema. The model literally
cannot emit malformed JSON; we then `JSONDecoder().decode(T.self, ...)`. This replaces
`_safely_parse_json` entirely.

Fallback ladder (per call, configurable):
1. Constrained decode → decode into `T`. (default)
2. If constrained sampler unavailable for a model: prompt with JSON instructions +
   tolerant extraction (strip fences, first balanced object) + **repair-retry** (feed
   the decode error back to the model once).
3. Hard fail → typed `AgentError`, surfaced in `WorkflowResult.errors` (engine never crashes).

**Status (M2, landed):** the portable, fully-tested form is in place — a typed `JSONSchema`
per agent output (single source of truth) drives prompt injection **and** post-generation
validation, with schema-aware repair-retry (`SchemaConstrainedDecoder`). This is the
fallback ladder's steps 1-guidance + 2 + 3, all CI-verifiable with a mock model. The hard
**GPU logit-masking** form (step 1 proper — making invalid tokens impossible via a
`LogitProcessor`, optionally `mlx-swift-structured`) is deferred behind the same
`SchemaConstrainedDecoding` protocol: it cannot be CI-verified (needs a GPU + model) and
`mlx-swift-structured` is `0.1.0`/single-maintainer, so it is gated to the integration
target rather than made foundational.

**Models:** quantized 4-bit open models from the MLX community — Qwen2.5-7B-Instruct as
default, with Llama-3.1-8B / Phi / Gemma swappable via config. Embeddings via a small
MLX embedder (e.g. `bge`/`gte` family) in `MLXEmbedders`. The current open-model survey
and a tiered (16/32/64 GB) recommendation that supersedes these placeholders lives in
[`MODELS.md`](MODELS.md).

---

## 4. Agents

```swift
public protocol Agent: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Decodable & Sendable & Schematized
    var name: String { get }
    var systemPrompt: String { get }
    func userPrompt(for input: Input) -> String
}
// run(_:using:config:) is a protocol extension that delegates to a SchemaConstrainedDecoding.
```

**Status (M3, landed).** Seven agents, each a thin wrapper carrying only its role
(`systemPrompt`, ported from the `_get_*_agent_prompt` methods with the redundant JSON
examples removed — the schema is injected by the decoder) and `userPrompt(for:)`. The
`run` extension delegates decoding to the M2 `SchemaConstrainedDecoder`, so agents hold no
inference/parsing logic (SRP) and are added by conformance (OCP). Every `Output` is
`Schematized`. The Proximity agent references hypotheses **by index**, not text, fixing the
Python string-equality fragility; it is the parity/fallback path and is superseded by the
embedding-based `ProximityAnalyzer` in M5 (behind a protocol). No per-agent state files;
persistence is centralized in the engine.

---

## 5. Engine & concurrency

`CoScientistEngine` is an `actor` holding the hypothesis set and metrics. Phases are
`async` methods mirroring the Python `_run_*_phase`. The iteration loop matches the
reference exactly so results are comparable. Structured concurrency gives us free
cancellation (a CLI Ctrl-C or app "stop" cleanly tears down in-flight work).

- Per-hypothesis work (reflection, evolution) uses `TaskGroup` to express parallelism;
  real overlap is bounded by the single-model serialization, so the win comes from
  **batched inference** (§7), not thread count.
- Elo updates stay sequential (order-sensitive), exactly as the reference.

State persistence: `Codable` snapshot of hypotheses + metrics to JSON (resumable runs),
replacing the swarms per-agent state blobs.

**Status (M4, landed).** `CoScientistEngine` is an `actor` that runs the full pipeline and
**never throws** — per-phase failures are recorded in `WorkflowResult.errors` and the run
continues (mirroring the reference's catch-all, but granular). It depends only on
`SchemaConstrainedDecoding`, so it runs on MLX in production and on a scripted mock in tests
(a complete workflow is unit-tested deterministically, no model). Tournament pairing uses an
injected seeded PRNG (`SeededGenerator`) for reproducibility; Elo (k=24) is the
authoritative final ranking, initial order is by review score. Reflection/evolution are
sequential for now (correctness first); `TaskGroup` batching is M7. Embedding-based
proximity replaces the LLM proximity agent in M5. Runnable via `aicoscientist "<goal>" --run`.
Persistence is implemented via `RunSnapshot`/`RunStore` (Codable JSON; CLI `--save`), enough
to save results and seed a future engine for continued refinement.

---

## 6. Where the Swift/MLX version is *superior*

1. **Embedding-based proximity.** *(M5, landed.)* `EmbeddingProximityAnalyzer` embeds each
   hypothesis via `MLXEmbedders` (default BGE-small) and clusters by cosine threshold with
   union-find (`EmbeddingClusterer`). Deterministic, GPU-accelerated, no JSON parsing, no
   fragile text matching — clusters reference stable `UUID`s. Lives behind the
   `ProximityAnalyzer` protocol with the LLM `AgentProximityAnalyzer` as fallback; the
   clustering math is pure-Swift in `Kit` and fully unit-tested with a mock embedder. The
   CLI workflow uses the embedding path.
2. **Constrained decoding** eliminates the entire JSON-parse-failure class.
3. **Batched generation.** MLX can generate many hypotheses / score many reviews in one
   batched pass — a structural speedup over the reference's sequential API calls.
4. **Shared-prefix KV cache.** All agents share large system prompts; cache the prefix
   to cut prefill cost across the hundreds of calls a run makes.
5. **Local, private, offline, zero marginal cost** — the whole point on Apple Silicon.
6. **Type safety end-to-end** — `Codable` contracts instead of `Dict[str, Any]`.

---

## 7. Performance levers (post-parity)

- Batched inference for generation & reflection phases.
- KV-cache reuse for shared system-prompt prefixes.
- Quantization tiers (4/6/8-bit) selectable per model.
- Keep the model resident in unified memory across the whole run (load once).

---

## 8. Milestones

- **M0 — Scaffold.** SPM package, targets, MLX deps, swift-log, CI (build + test on macOS).
- **M1 — Inference core.** Load a quantized model, `LanguageModel` + `ModelActor`, plain text generation working end-to-end.
- **M2 — Structured output.** Codable output types + `StructuredSampler` + repair-retry fallback; prove on one agent (Tournament judge — smallest schema).
- **M3 — Domain + agents.** Port `Hypothesis`, Elo, and all 7 system prompts; typed outputs for each.
- **M4 — Engine.** Full phase pipeline + iteration loop + metrics + state persistence. Parity target: same workflow shape as Python.
- **M5 — Embedding proximity.** MLX embeddings + clustering replacing the LLM proximity agent.
- **M6 — CLI + parity test.** ArgumentParser CLI mirroring `example.py`; run the same research goal and compare structure/quality against the Python output.
- **M7 — Optimize.** Batching, prefix KV cache, quant tiers.

---

## 9. Risks

- **MLX-Swift API churn** — pin versions; isolate behind `LanguageModel`.
- **Constrained-decoding effort** — grammar-from-schema is the hardest single component; M2 de-risks it early and the fallback ladder keeps the engine usable meanwhile.
- **Model quality at 4-bit** — smaller local models reason worse than GPT-4; mitigated by constrained output, repair-retry, and swappable models.
- **Memory** — 7–8B 4-bit (~5–6 GB) plus embedder fits comfortably on 16 GB+; document a minimum.
```
