---
name: mlx-swift
description: Write correct, idiomatic MLX-Swift for local LLMs and embeddings on Apple Silicon. Use when working in the coscientist-mlx project or any Swift 6 / Apple-Silicon package that uses mlx-swift or mlx-swift-lm — model loading, text generation, structured/JSON-schema-constrained decoding, embeddings, KV/prompt cache, quantization, GPU memory limits, lazy evaluation, and the Swift-6 concurrency rules around the non-Sendable MLXArray.
---

# MLX-Swift Development Guide

Idiomatic, current (June 2026) MLX-Swift for running open models **locally on Apple
Silicon**. This is the *Swift* binding — its API differs from Python MLX (`mlx-dev`
skill). Facts here are verified against package source at the pinned tags; treat the
canonical source files (see end) as the final authority and re-verify before relying on
any signature, because this ecosystem churns fast.

## The packages (verified, current)

The LLM/embedding libraries **moved out of `mlx-swift-examples`** into a dedicated
package. Depend on these:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.31.4"),
    .package(url: "https://github.com/ml-explore/mlx-swift-lm", .upToNextMajor(from: "3.31.3")),
]
// Products:
//   mlx-swift     → MLX, MLXNN, MLXOptimizers, MLXRandom, MLXFFT, MLXLinalg, MLXFast
//   mlx-swift-lm  → MLXLLM, MLXLMCommon, MLXVLM, MLXEmbedders, MLXHuggingFace
```

`mlx-swift-lm` pulls in `mlx-swift`, `swift-transformers` (Tokenizers), and
`swift-huggingface` transitively. `mlx-swift-examples` is now only sample apps —
**do not** depend on it for library code. Platforms: macOS 14+ (Apple Silicon).

For structured output, add (see `references/structured-output.md`):
```swift
.package(url: "https://github.com/ajevans99/swift-json-schema", from: "0.4.0"),       // @Schemable: Codable → JSON Schema
.package(url: "https://github.com/petrukha-ivan/mlx-swift-structured", from: "0.1.0"), // XGrammar constrained decoding (early, 0.1.0)
```

## Rule #1 — `MLXArray` is NOT `Sendable`

This dominates every design decision under Swift 6 strict concurrency.

- `MLXArray` is a `final class` with **no** `Sendable` conformance. Passing one across an
  actor/`Task`/isolation boundary is a compile error.
- Therefore: **keep all array work inside `ModelContainer.perform { … }`** (the library's
  own isolation). Return only `Sendable` values (`String`, `[Float]`, your `Codable`
  structs) from `perform`. Never let an `MLXArray` escape.
- Wrap the model in your own `actor` (e.g. `ModelActor`) to serialize GPU access; MLX
  evaluation is internally lock-serialized anyway, so one resident model + one actor is
  the correct, not limiting, design. Use **batching**, not threads, for throughput.
- `Device` is `@unchecked Sendable`; `DType`, `DeviceType`, `Memory.Snapshot` are `Sendable`.

## Loading a model

High level (recommended) — `ChatSession` from `MLXLMCommon`:

```swift
import MLXLLM
import MLXLMCommon

let container = try await #huggingFaceLoadModelContainer(
    configuration: LLMRegistry.qwen2_5_7b   // → mlx-community/Qwen2.5-7B-Instruct-4bit
)
let session = ChatSession(container, instructions: "You are a careful scientific reviewer.")
let answer = try await session.respond(to: "Critique this hypothesis: …")
```

`LLMRegistry` has ~40 entries. Verified ids include `qwen2_5_7b`, `llama3_2_3B_4bit`,
`llama3_1_8B_4bit`, `mistral7B4bit`, `phi3_5_4bit`, `gemma3_1B_qat_4bit`. For strong
JSON/instruction following at ~5 GB, default to **Qwen2.5-7B-Instruct-4bit**. See
`references/inference.md` for the lower-level `LLMModelFactory.loadContainer(...)` path.

## Generating text

The current API is **AsyncStream-based**; the old closure/callback `generate` is
deprecated. `Generation` is an enum: `.chunk(String)`, `.info(GenerateCompletionInfo)`,
`.toolCall(ToolCall)`.

```swift
import MLXLMCommon

for try await item in session.streamResponse(to: prompt) {
    print(item, terminator: "")   // ChatSession streams decoded String chunks
}
```

`GenerateParameters` (verified defaults): `temperature: Float = 0.6`, `topP = 1.0`,
`topK = 0`, `minP = 0.0`, `maxTokens: Int? = nil`, repetition/presence/frequency
penalties, and KV-quantization knobs (`kvBits`, `kvGroupSize`, `quantizedKVStart`).
Full generation detail, `TokenIterator`, and the custom-sampler injection point are in
`references/inference.md`.

## Structured output — the project's crux

Small local models break free-form JSON; do **not** reproduce the Python
`_safely_parse_json` regex gauntlet. Hide the strategy behind a protocol (DIP) and prefer
**constrained decoding**:

1. **Primary — schema-constrained decoding.** `MLXLMCommon` exposes
   `protocol LogitProcessor { mutating func prompt(_:); func process(logits:) -> MLXArray; mutating func didSample(token:) }`
   and a `TokenIterator(input:model:cache:processor:sampler:…)` that accepts it. Mask
   disallowed tokens to `-inf`. `mlx-swift-structured` already implements this over
   XGrammar with `Grammar.schema(_:)` / `Grammar.generable(_:)`.
2. **Schema from types.** `swift-json-schema`'s `@Schemable` macro derives a JSON Schema
   from a Codable type and validates instances — pair it with (1).
3. **Fallback ladder** for models/configs without a grammar: strict JSON prompt →
   tolerant extract → **decode-error-fed repair retry (once)** → typed error.

Decode straight into your `Codable` agent-output structs. Details, code, and the
maturity caveat on the 0.1.0 dependency: `references/structured-output.md`.

## Embeddings & similarity (proximity phase)

Use `MLXEmbedders` for real embedding-based clustering instead of an LLM judging
similarity. Load with `loadModelContainer(using:configuration:)`, embed inside
`container.perform { … }`, pool with `normalize: true`, then cosine = dot product:
`matmul(embeddings, embeddings.T)`. Models + full snippet: `references/embeddings.md`.

## Memory, KV cache, quantization (quick refs)

- GPU cache limit: **`Memory.cacheLimit = …`** (the old `GPU.set(cacheLimit:)` is deprecated).
  Also `Memory.memoryLimit`, `.activeMemory`, `.peakMemory`, `.snapshot()`.
- Prompt/KV cache is public: `makePromptCache(model:)`, `save/loadPromptCache(url:)`,
  `trimPromptCache(_:numTokens:)`. Reuse a shared system-prompt prefix across agents.
- Quantization: model-level free fn `quantize(model:groupSize:bits:mode:)` (defaults
  `64`/`4`/`.affine`); op-level is `quantized(_:)` (note: op is *-ed*, model fn is not).
- Lazy eval: `eval(...)` / `asyncEval(...)` / `checkedEval(...) throws`. Compute is lazy
  until eval (or `print`/memory access). Prefer `asyncEval` for overlap; never eval in a
  tight inner loop. Detail: `references/memory-and-perf.md` + `references/concurrency.md`.

## Engineering standards (this is a public project)

Cardinal values — apply them to MLX code specifically:

- **TDD/BDD, not rubberstamping.** Write the failing test first. MLX is non-deterministic
  unless seeded — seed with `MLXRandom.seed(_:)` and set `temperature: 0` for
  deterministic assertions. Put pure logic (Elo, clustering, schema decode) behind
  protocols and test it with a **mock `LanguageModel`** — no model download in unit tests.
  Reserve real-model runs for a separate, opt-in integration test target.
- **Clean Architecture / DIP.** The domain/engine must depend on a `LanguageModel` /
  `EmbeddingModel` / `StructuredDecoder` **protocol**, never on `MLX*` types directly. All
  `import MLX*` lives in the `Inference`/`Embeddings` adapter layer. This keeps the core
  testable, swappable (a future llama.cpp or remote backend), and MLX-churn-proof.
- **SOLID.** One agent = one responsibility; new agents/samplers via new conformances
  (OCP), not edits to the engine. Small protocols (ISP).
- **Clean Code.** Let non-Sendable `MLXArray` enforce boundaries for you; surface errors
  as typed `enum`s; no `try?`-swallowing of generation failures (record them in
  `WorkflowResult.errors`).
- **Best option even when hardest.** Constrained decoding > prompt-and-pray; embedding
  clustering > LLM-judged string matching; verify APIs against source > trusting memory.

## Verify-before-trust (known uncertainties from research)

- Concrete `LogitSampler`/`LogitProcessor` *implementation* type names (e.g. argmax/top-p)
  were not verified — confirm in `Evaluate.swift`/`Sample.swift` before naming them.
- Whether `MLXLinalg` is a product of `mlx-swift-lm` vs only `mlx-swift` — unconfirmed.
- The cosine-similarity one-liners are idiomatic MLX ops, not a documented API.
- `mlx-swift-structured` is **0.1.0, single maintainer** — gate it behind the
  `StructuredDecoder` protocol so it is replaceable.

## Canonical sources (re-verify here)

- `https://github.com/ml-explore/mlx-swift` (core; `Source/MLX/*.swift`)
- `https://github.com/ml-explore/mlx-swift-lm` (LLM/embeddings; `Libraries/*/`)
  - `Libraries/MLXLMCommon/Evaluate.swift` — `generate`, `GenerateParameters`, `LogitProcessor`, `TokenIterator`
  - `Libraries/MLXLMCommon/ChatSession.swift`, `.../KVCache.swift`, `.../Chat.swift`
  - `Libraries/MLXLLM/LLMModelFactory.swift` — `LLMRegistry` + HF ids
  - `Libraries/MLXEmbedders/README.md`, `.../ModelFactory.swift`, `.../Pooling.swift`
- `https://github.com/petrukha-ivan/mlx-swift-structured`, `https://github.com/ajevans99/swift-json-schema`
