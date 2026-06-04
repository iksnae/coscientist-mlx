# Architecture

How the kit is layered, why it depends only on protocols, and where the Swift + MLX
version improves on the Python reference.

## Overview

coscientist-mlx is split into three targets so the testable domain logic never touches
the MLX runtime:

| Target | Role | MLX? |
|---|---|---|
| `AICoScientistKit` | Pure domain, agents, engine, protocol boundaries | **No** |
| `AICoScientistMLX` | On-device adapter — the only place `import MLX*` appears | Yes |
| `AICoScientistRemote` | Hosted OpenAI-compatible adapter | No |
| `AICoScientistCLI` | The `aicoscientist` driver; routes per stage | via MLX |

This is the Dependency Inversion Principle in practice: the engine and the seven agents
are written against ``LanguageModel``, ``EmbeddingModel``, and ``SchemaConstrainedDecoding``,
so unit tests run on a deterministic ``MockLanguageModel`` with no GPU and no downloads,
while production wires in the MLX-backed (or remote) implementations.

![Layering: the aicoscientist CLI drives the CoScientist Engine and seven agents inside AICoScientistKit, which depends only on the LanguageModel and EmbeddingModel protocols; AICoScientistMLX and AICoScientistRemote implement those protocols.](architecture)

## The decoding pipeline

Local open models are not guaranteed to emit valid JSON. Rather than parse best-effort,
each agent output is a `Codable`, ``Schematized`` type whose ``JSONSchema`` is the
single source of truth: it drives both the prompt injected into the model **and**
post-generation validation.

``SchemaConstrainedDecoder`` implements a fallback ladder:

1. Schema-guided prompt → tolerant extraction (``JSONExtraction``) → decode into the type.
2. On a decode/validation error, feed the error back to the model for a bounded
   **repair-retry**.
3. Hard failure surfaces as a typed ``AgentError``, recorded in ``ExecutionMetrics`` —
   the engine continues.

![Schema-constrained decode: inject the schema into the prompt, generate, extract JSON and strip reasoning, then validate against the schema; on success decode the value, on failure repair-retry by feeding the error back, and when retries are exhausted record an AgentError in metrics.](decode)

A heavier GPU logit-masking form (making invalid tokens impossible) sits behind the same
``SchemaConstrainedDecoding`` protocol and is gated to the integration target, since it
needs a GPU to verify.

## Concurrency

``CoScientistEngine`` is an `actor` holding the hypothesis set and metrics. Phases are
`async` methods that mirror the reference's pipeline shape so results are comparable.
Tournament pairing uses an injected ``SeededGenerator`` for reproducible runs, and Elo
updates stay sequential (order-sensitive), exactly as the reference. Because MLX
evaluation is internally serialized, throughput comes from batched inference rather than
thread count.

## Where the Swift/MLX version is superior

1. **Embedding-based proximity** — ``EmbeddingProximityAnalyzer`` embeds each hypothesis
   and clusters by cosine threshold with union-find (``EmbeddingClusterer``);
   deterministic, GPU-accelerated, referencing stable `UUID`s. The LLM
   ``AgentProximityAnalyzer`` remains as a fallback behind ``ProximityAnalyzer``.
2. **Constrained decoding** eliminates the JSON-parse-failure class entirely.
3. **Local, private, offline, zero marginal cost** on Apple Silicon.
4. **Type safety end-to-end** — `Codable` contracts instead of untyped dictionaries.

For the full design, milestones, and the mapping from the Python reference, see
[`docs/ARCHITECTURE.md`](https://github.com/iksnae/coscientist-mlx/blob/main/docs/ARCHITECTURE.md)
in the repository.
