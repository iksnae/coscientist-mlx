# Memory, KV/prompt cache, quantization, performance

Verified against `mlx-swift` 0.31.4 and `mlx-swift-lm` 3.31.3. Re-verify in source.

## GPU memory & cache — API moved

The old `MLX.GPU.set(cacheLimit:)` / `GPU.set(memoryLimit:)` / `GPU.clearCache()` /
`GPU.cacheLimit` are all `@available(*, deprecated)` and forward to the new `Memory` enum
(`Source/MLX/Memory.swift`):

```swift
public enum Memory {
    public static var cacheLimit: Int { get set }    // bytes; replaces GPU.set(cacheLimit:)
    public static var memoryLimit: Int { get set }
    public static var activeMemory: Int { get }
    public static var cacheMemory: Int { get }
    public static var peakMemory: Int { get }
    public static func snapshot() -> Snapshot        // Sendable, Codable
    public static func clearCache()
    public static func withWiredLimit<R>(...) -> R
}
```
Use `Memory.cacheLimit = N`, not `GPU.set(...)`. Still on `GPU` (not deprecated):
`startCapture(url:)`, `stopCapture(url:)`, `resetPeakMemory()`, `deviceInfo()`,
`maxRecommendedWorkingSetBytes()`.

Typical: set a `Memory.cacheLimit` to bound the cache, snapshot `peakMemory` after a run
for the metrics, document a minimum RAM (7–8B 4-bit ≈ 5–6 GB resident + embedder).

## Prompt / KV cache (real public API)

From `Libraries/MLXLMCommon/KVCache.swift`:
```swift
public func makePromptCache(model: any LanguageModel,
                            parameters: GenerateParameters? = nil) -> [KVCache]
public func savePromptCache(url: URL, cache: [KVCache], metadata: [String:String] = [:]) throws
public func loadPromptCache(url: URL) throws -> ([KVCache], [String:String])
public func canTrimPromptCache(_ cache: [KVCache]) -> Bool
@discardableResult public func trimPromptCache(_ cache: [KVCache], numTokens: Int) -> Int
public func maybeQuantizeKVCache(cache: inout [KVCache],
    kvBits: Int?, kvGroupSize: Int = 64, quantizedKVStart: Int = 0)
```
Concrete caches: `KVCacheSimple`, `RotatingKVCache`, `QuantizedKVCache`, `ChunkedKVCache`,
`MambaCache`. Pass `cache:` into `ChatSession.init`, `generate(...)`, or `TokenIterator`.
`ChatSession` also has `saveCache(to:)`.

**Project use:** the 8 agents share large system prompts. Build a prompt cache for the
shared prefix once and reuse it across calls to cut prefill cost over a run's hundreds of
generations. Quantize the KV cache (`kvBits: 4/8`) for long contexts.

## Quantization
- Model-level (mutates in place), `Source/MLXNN/Quantized.swift`:
  ```swift
  public func quantize(model: Module, groupSize: Int = 64, bits: Int = 4,
                       mode: QuantizationMode = .affine,
                       filter: (String, Module) -> Bool = { _,_ in true },
                       apply: ... = quantizeSingle(...))
  ```
  Defaults quantize `Linear` + `Embedding` at 4-bit/group-64. Usually unnecessary — load
  pre-quantized `mlx-community/*-4bit` repos directly.
- Op-level: `quantized(_:)` / `dequantized(_:)` / `quantizedMM(_:)` (`quantizedMatmul` is
  deprecated). Note the naming: the **op** is `quantized` (past tense), the **model fn** is
  `quantize`.

## Performance notes (from MLX guidance, carry over to Swift)
- Quantized LLM inference is MLX's strength; 4-bit ≈ 4× memory bandwidth.
- Prefer batching over threads (eval is lock-serialized; `MLXArray` non-Sendable).
- `bfloat16`/`float16` for 2× bandwidth on non-quantized paths.
- `asyncEval` to overlap; eval at coarse boundaries only.
- `float64` is CPU-only — never send it to the GPU stream.
- Load the model once and keep it resident (unified memory; no host/device copies).
