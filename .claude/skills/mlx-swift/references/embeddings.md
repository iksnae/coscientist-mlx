# Embeddings & similarity (MLXEmbedders)

For the proximity/clustering phase, use real embeddings instead of asking an LLM to judge
similarity (the Python reference does the latter, then matches by exact string equality —
fragile and slow). Verified against `mlx-swift-lm` `Libraries/MLXEmbedders/` on `main`.

## Load + embed (current API)

```swift
import MLXEmbedders
import MLXEmbeddersHuggingFace
import MLXLMTokenizers

let container = try await loadModelContainer(
    using: TokenizersLoader(),
    configuration: .bge_small            // or .nomic_text_v1_5, .gte_tiny, …
)

let texts = ["hypothesis A …", "hypothesis B …", "hypothesis C …"]

let vectors: [[Float]] = await container.perform {
    (model: EmbeddingModel, tokenizer: Tokenizer, pooling: Pooling) -> [[Float]] in
    let inputs = texts.map { tokenizer.encode(text: $0, addSpecialTokens: true) }
    let maxLen = inputs.reduce(into: 16) { $0 = max($0, $1.count) }
    let padded = stacked(inputs.map {
        MLXArray($0 + Array(repeating: tokenizer.eosTokenId ?? 0, count: maxLen - $0.count))
    })
    let mask = (padded .!= (tokenizer.eosTokenId ?? 0))
    let tokenTypes = MLXArray.zeros(like: padded)
    let pooled = pooling(
        model(padded, positionIds: nil, tokenTypeIds: tokenTypes, attentionMask: mask),
        normalize: true, applyLayerNorm: true)
    pooled.eval()
    return pooled.map { $0.asArray(Float.self) }   // [[Float]] is Sendable — safe to return
}
```

Key concurrency point: all `MLXArray` work stays inside `perform`; only `[[Float]]`
escapes. `Pooling.Strategy`: `.mean`, `.cls`, `.first`, `.last`, `.max`, `.none`.

## Verified models → HF repos
Most point at the original org repos (MLXEmbedders converts on the fly):

| Constant | HF repo |
|---|---|
| `.bge_micro` | `TaylorAI/bge-micro-v2` |
| `.gte_tiny` | `TaylorAI/gte-tiny` |
| `.minilm_l6` | `sentence-transformers/all-MiniLM-L6-v2` |
| `.bge_small` | `BAAI/bge-small-en-v1.5` |
| `.bge_base` | `BAAI/bge-base-en-v1.5` |
| `.bge_large` | `BAAI/bge-large-en-v1.5` |
| `.bge_m3` | `BAAI/bge-m3` |
| `.nomic_text_v1_5` | `nomic-ai/nomic-embed-text-v1.5` (Matryoshka) |
| `.mixedbread_large` | `mixedbread-ai/mxbai-embed-large-v1` |
| `.qwen3_embedding` | `mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ` |

Default for short hypothesis texts: `.bge_small` (fast, 384-dim, good quality). Or pass any
repo: `.init(id: "some-org/embedder")`.

## Cosine similarity matrix

With `normalize: true`, vectors are L2-normalized, so cosine == dot product:
```swift
import MLX
// embeddings: MLXArray of shape [N, D], rows already normalized
let sims = matmul(embeddings, embeddings.T)   // [N, N] cosine-similarity matrix
```
If not normalized: `let n = embeddings / sqrt(sum(embeddings * embeddings, axis: -1, keepDims: true))`.
NOTE: these are standard `mlx-swift` ops; the exact one-liner is idiomatic, not a
documented helper — verify `matmul`/`.T`/`sum` signatures in `mlx-swift` `Source/MLX/Ops.swift`.

## Clustering (pure Swift, testable)

Keep clustering out of MLX so it is deterministic and unit-testable on `[[Float]]`:
- Threshold/connected-components: edge if cosine ≥ τ (τ≈0.80–0.85 for short scientific
  text; tune empirically), then union-find → clusters. Assign each `Hypothesis` a stable
  cluster id by its `UUID` (never by text equality).
- Or agglomerative (average-linkage) if you want a dendrogram.

This phase becomes deterministic, GPU-accelerated for the embed step, and free of any LLM
JSON parsing — a strict improvement over the reference.
