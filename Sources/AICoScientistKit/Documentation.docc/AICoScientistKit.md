# ``AICoScientistKit``

A native Swift implementation of the multi-agent "AI co-scientist" methodology —
generating, peer-reviewing, ranking, and evolving scientific research hypotheses,
with every dependency on a language or embedding model expressed as a protocol.

## Overview

`AICoScientistKit` is the pure domain and orchestration layer of **coscientist-mlx**,
a Swift + [MLX](https://github.com/ml-explore/mlx-swift) port of the methodology from
Google's *Towards an AI co-scientist* (Gottweis et al., 2025,
[arXiv:2502.18864](https://arxiv.org/abs/2502.18864)). It contains **no `import MLX`** —
the engine and agents depend only on the ``LanguageModel`` and ``EmbeddingModel``
protocols, so the kit is fast to unit-test with a mock backend and the heavy MLX adapter
(`AICoScientistMLX`) is swappable behind the same seams.

The system follows a *generate → debate → evolve* loop. A ``CoScientistEngine``
orchestrates seven single-responsibility agents over an iterative pipeline, using an
Elo tournament for self-play ranking and embedding-based clustering for diversity:

![System design: a scientist provides a research goal; the multi-agent engine runs Generation, Reflection, Ranking, Tournament, Meta-Review, Evolution, and Proximity in a self-improving loop, routes each stage to an on-device MLX or remote backend, and returns the top-ranked hypotheses with a meta-review and clusters.](system-design)

The per-agent loop in detail:

![The seven-agent pipeline: an initial generation/reflection/ranking/tournament pass followed by an N-times refinement loop of meta-review, evolution, reflection, ranking, tournament, and proximity clustering.](pipeline)

Start a run with just a research goal and a model:

```swift
import AICoScientistKit
import AICoScientistMLX

let model = try await MLXLanguageModel.load()
let decoder = SchemaConstrainedDecoder(model: model)
let engine = CoScientistEngine(router: StaticDecoderRouter(decoder))

let result = await engine.run(researchGoal: "Improve lithium-ion energy density")
for h in result.topRankedHypotheses {
    print(h.eloRating, h.text)
}
```

The engine **never throws**: per-phase failures are captured in
``WorkflowResult/metrics`` and ``ExecutionMetrics/decodeFailures`` and the run
continues, mirroring the reference's catch-all behaviour with finer granularity.

### How it differs from the Python reference

- **Embedding-based proximity** (``EmbeddingProximityAnalyzer``) replaces fragile
  LLM-judged, string-matched clustering with deterministic cosine + union-find over
  stable `UUID`s.
- **Schema-driven decoding** (``SchemaConstrainedDecoding``) eliminates the JSON-parse
  failure class that small local models otherwise hit.
- **Type-safe contracts** — every agent output is a `Codable`, ``Schematized`` struct
  rather than `Dict[str, Any]`.

> Not to be confused with Sakana AI's *The AI Scientist*
> ([arXiv:2408.06292](https://arxiv.org/abs/2408.06292)), an unrelated end-to-end
> paper-writing system. This project ports Google's hypothesis-generation *co-scientist*.

## Topics

### Guides

- <doc:Architecture>
- <doc:TheSevenAgents>
- <doc:ModelsAndDevices>

### Essentials

- ``CoScientistEngine``
- ``EngineConfiguration``
- ``Hypothesis``
- ``WorkflowResult``
- ``ExecutionMetrics``

### The Seven Agents

- ``Agent``
- ``GenerationAgent``
- ``ReflectionAgent``
- ``RankingAgent``
- ``TournamentAgent``
- ``MetaReviewAgent``
- ``EvolutionAgent``
- ``ProximityAgent``

### Inference & Structured Decoding

- ``LanguageModel``
- ``GenerationConfig``
- ``AgentError``
- ``StructuredDecoder``
- ``LanguageModelStructuredDecoder``
- ``SchemaConstrainedDecoding``
- ``SchemaConstrainedDecoder``
- ``JSONExtraction``
- ``DecodeMetrics``
- ``Transcript``
- ``TranscriptEntry``
- ``MockLanguageModel``

### Schema

- ``JSONSchema``
- ``Schematized``
- ``JSONValue``

### Embeddings & Proximity

- ``EmbeddingModel``
- ``EmbeddingClusterer``
- ``ProximityAnalyzer``
- ``EmbeddingProximityAnalyzer``
- ``AgentProximityAnalyzer``

### Engine Internals

- ``AgentRole``
- ``DecoderRouting``
- ``StaticDecoderRouter``
- ``RoleDecoderRouter``
- ``RunSnapshot``
- ``RunStore``
- ``SeededGenerator``
- ``BuildInfo``
- ``Log``

### Core Data Model

- ``ReviewScores``
- ``HypothesisReview``
- ``TournamentJudgment``
- ``SimilarityCluster``

### Agent Inputs & Outputs

- ``GenerationInput``
- ``GeneratedHypothesis``
- ``GeneratedHypotheses``
- ``ReflectionInput``
- ``RankingInput``
- ``RankedHypothesis``
- ``RankedHypotheses``
- ``TournamentInput``
- ``MetaReviewInput``
- ``ProcessAssessment``
- ``MetaReview``
- ``EvolutionInput``
- ``Refinement``
- ``EvolvedHypothesis``
- ``ProximityInput``
- ``ProximityCluster``
- ``ProximityResult``
