# Inference — loading & generation (MLXLLM / MLXLMCommon)

Verified against `mlx-swift-lm` `main` (v3.31.3, Apr 2026). Re-verify against
`Libraries/MLXLMCommon/Evaluate.swift` before relying on a signature.

## Loading

### Convenience macro (recommended)
```swift
import MLXLLM
import MLXLMCommon
import MLXHuggingFace

let container: ModelContainer = try await #huggingFaceLoadModelContainer(
    configuration: LLMRegistry.qwen2_5_7b
)
```

### Custom configuration (any HF repo)
```swift
let cfg = ModelConfiguration(
    id: "mlx-community/Qwen2.5-7B-Instruct-4bit",
    defaultPrompt: "…"            // optional; also: extraEOSTokens, toolCallFormat
)
let container = try await #huggingFaceLoadModelContainer(configuration: cfg)
```

### Lower-level factory (explicit downloader/tokenizer — 3.x change)
```swift
public final class LLMModelFactory: GenericModelFactory {
    public static let shared = LLMModelFactory(
        typeRegistry: LLMTypeRegistry.shared, modelRegistry: LLMRegistry.shared)
}

func loadContainer(
    from downloader: any Downloader,
    using tokenizerLoader: any TokenizerLoader,
    configuration: ModelConfiguration,
    useLatest: Bool = false,
    progressHandler: @Sendable @escaping (Progress) -> Void
) async throws -> ModelContainer

func loadContainer(from directory: URL, using tokenizerLoader: any TokenizerLoader)
    async throws -> ModelContainer   // load from a local directory (offline)
```
Note the 3.x breaking change: the old
`LLMModelFactory.shared.loadContainer(configuration:progressHandler:)` now requires an
explicit `Downloader` + `TokenizerLoader`. The `#huggingFaceLoadModelContainer` macro
supplies them for you.

### Verified `LLMRegistry` ids → HF repos
| Constant | HF repo |
|---|---|
| `qwen2_5_7b` | `mlx-community/Qwen2.5-7B-Instruct-4bit` |
| `llama3_2_3B_4bit` | `mlx-community/Llama-3.2-3B-Instruct-4bit` |
| `llama3_1_8B_4bit` | `mlx-community/Meta-Llama-3.1-8B-Instruct-4bit` |
| `mistral7B4bit` | `mlx-community/Mistral-7B-Instruct-v0.3-4bit` |
| `phi3_5_4bit` | `mlx-community/Phi-3.5-mini-instruct-4bit` |
| `gemma3_1B_qat_4bit` | `mlx-community/gemma-3-1b-it-qat-4bit` |

## Chat templating
```swift
public enum Chat {
    public struct Message {
        public var role: Role        // .user .assistant .system .tool
        public var content: String
        public var images: [UserInput.Image]
        public var videos: [UserInput.Video]
        public static func system(_:) -> Self
        public static func user(_:) -> Self
        public static func assistant(_:) -> Self
        public static func tool(_:) -> Self
    }
}
```
`ChatSession` applies the model's chat template internally. Seed history with
`ChatSession(container, history: [Chat.Message])`; system prompt via `instructions:`.

## Generation — current AsyncStream API

```swift
public func generate(
    input: LMInput,
    cache: [KVCache]? = nil,
    parameters: GenerateParameters,
    context: ModelContext,
    wiredMemoryTicket: WiredMemoryTicket? = nil,
    tools: [[String: any Sendable]]? = nil
) throws -> AsyncStream<Generation>

public func generateTokens(   // raw token ints
    input: LMInput, cache: [KVCache]? = nil,
    parameters: GenerateParameters, context: ModelContext,
    includeStopToken: Bool = false, wiredMemoryTicket: WiredMemoryTicket? = nil
) throws -> AsyncStream<TokenGeneration>

public enum Generation { case chunk(String), info(GenerateCompletionInfo), toolCall(ToolCall) }
```
The closure-callback `generate(...) -> GenerateResult` forms are
`@available(*, deprecated)`. Collect a full string:
```swift
var text = ""
for await g in try generate(input: input, parameters: params, context: ctx) {
    if case .chunk(let s) = g { text += s }
}
```

## `GenerateParameters` (verified defaults)
```swift
public init(
    maxTokens: Int? = nil,
    maxKVSize: Int? = nil,
    kvBits: Int? = nil, kvGroupSize: Int = 64, quantizedKVStart: Int = 0,
    temperature: Float = 0.6, topP: Float = 1.0, topK: Int = 0, minP: Float = 0.0,
    repetitionPenalty: Float? = nil, repetitionContextSize: Int = 20,
    presencePenalty: Float? = nil, presenceContextSize: Int = 20,
    frequencyPenalty: Float? = nil, frequencyContextSize: Int = 20,
    prefillStepSize: Int = 512
)
func sampler() -> LogitSampler
func processor() -> LogitProcessor?
```
For deterministic tests: `temperature: 0` + `MLXRandom.seed(_:)`.

## Manual loop / custom sampling (`TokenIterator`)
```swift
public init(
    input: LMInput, model: any LanguageModel,
    cache: [KVCache]? = nil,
    processor: LogitProcessor?,   // inject constraints here
    sampler: LogitSampler,
    prefillStepSize: Int = 512, maxTokens: Int? = nil
) throws
```
The `init(prompt:…)` form is deprecated → use `init(input:model:cache:parameters:)` or the
processor/sampler overload above. `SpeculativeTokenIterator` exists for speculative decoding.

UNCERTAIN: concrete built-in sampler/processor type names returned by
`GenerateParameters.sampler()/.processor()` were not verified — confirm in source.
