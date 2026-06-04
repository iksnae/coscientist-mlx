# ``AICoScientistMLX``

The Apple-Silicon adapter: MLX-backed implementations of the model protocols that
`AICoScientistKit` depends on.

## Overview

This is the **only** module that imports MLX. It provides concrete, GPU-accelerated
conformances to the two protocols the domain layer is written against — keeping the kit
itself MLX-free and unit-testable (Dependency Inversion):

- ``MLXLanguageModel`` conforms to `AICoScientistKit.LanguageModel`.
- ``MLXEmbeddingModel`` conforms to `AICoScientistKit.EmbeddingModel`.
- ``MLXRuntime`` exposes runtime knobs (e.g. the GPU cache limit) for the MLX backend.

Each model is an `actor`, serializing GPU access — correct because MLX evaluation is
internally lock-serialized, so one resident model behind one actor is the right shape.
Only `Sendable` values cross the isolation boundary; the non-`Sendable` `MLXArray` work
stays inside the container.

### Loading and running

The `load` helpers download (on first use) and resident-load a quantized model. The
defaults are validated for clean JSON and small footprint:

- ``MLXLanguageModel`` default: `mlx-community/Qwen3-4B-Instruct-2507-4bit`.
- ``MLXEmbeddingModel`` default: `mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ`.

```swift
import AICoScientistKit
import AICoScientistMLX

// On memory-constrained devices, cap the Metal cache first (see docs/IOS.md).
MLXRuntime.setGPUCacheLimit(bytes: 20 * 1024 * 1024)

let model = try await MLXLanguageModel.load()                 // default model
let embedder = try await MLXEmbeddingModel.load()             // default embedder

let engine = CoScientistEngine(
    router: StaticDecoderRouter(SchemaConstrainedDecoder(model: model)),
    proximityAnalyzer: EmbeddingProximityAnalyzer(model: embedder)
)
let result = await engine.run(researchGoal: "Improve perovskite solar-cell stability")
```

Pass a Hugging Face repo id to override the default without importing any MLX types:

```swift
let big = try await MLXLanguageModel.load(modelId: "mlx-community/Qwen3-8B-4bit-DWQ")
```

For model tiers, the role-aware split, and on-device constraints, see the
**Models & Devices** guide in the `AICoScientistKit` documentation, and
[`docs/MODELS.md`](https://github.com/iksnae/coscientist-mlx/blob/main/docs/MODELS.md) /
[`docs/IOS.md`](https://github.com/iksnae/coscientist-mlx/blob/main/docs/IOS.md) in the repo.

## Topics

### Model Adapters

- ``MLXLanguageModel``
- ``MLXEmbeddingModel``

### Runtime

- ``MLXRuntime``
