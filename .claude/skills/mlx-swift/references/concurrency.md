# Swift 6 concurrency with MLX

The defining constraint: **`MLXArray` is not `Sendable`.** Design around it; do not fight it.

## What is / isn't Sendable (verified)
- `MLXArray` — `final class`, **NOT Sendable**. Cannot cross actor/`Task`/isolation
  boundaries. (This is a feature: it forces arrays to stay where they're computed.)
- `Device` — `@unchecked Sendable`. `DType`, `DeviceType`, `Memory.Snapshot` — `Sendable`.
- `ModelContainer` — the library's isolation wrapper; you interact via `perform { … }`.

## The rule
Do all array work inside `ModelContainer.perform { … }` and return only `Sendable`
values (`String`, `[Float]`, `Int`, your `Codable` structs). An `MLXArray` must never
escape `perform`.

```swift
// GOOD — only String escapes
let text: String = await container.perform { (model, tokenizer) in
    var s = ""
    for await g in try generate(input: input, parameters: p, context: ctx) {
        if case .chunk(let c) = g { s += c }
    }
    return s
}

// COMPILE ERROR — MLXArray is not Sendable
let logits: MLXArray = await container.perform { … return someArray }   // ✗
```

## Project pattern: `ModelActor` + protocol boundary

```swift
public protocol LanguageModel: Sendable {
    func generateText(system: String, user: String, config: GenerationConfig) async throws -> String
}

public actor ModelActor: LanguageModel {
    private let container: ModelContainer            // loaded once, resident
    public init(_ container: ModelContainer) { self.container = container }

    public func generateText(system: String, user: String,
                             config: GenerationConfig) async throws -> String {
        try await container.perform { model, tokenizer in
            // build LMInput from a Chat with .system(system)/.user(user); generate; return String
        }
    }
}
```
- The engine depends on `LanguageModel` (protocol), not `ModelActor` or any `MLX*` type —
  so the core compiles and tests without MLX, and the backend is swappable (DIP).
- One resident model behind one actor is correct: MLX evaluation is internally
  lock-serialized (a shared recursive `evalLock`), so concurrent multi-thread eval buys
  nothing. For throughput use **batched generation**, not more threads.

## Lazy evaluation
- `eval(_:)`, `asyncEval(_:)`, `checkedEval(_:) throws` (the throwing variant surfaces MLX
  errors). Variadic `eval(_ values: Any...)` accepts arrays, dicts, tuples.
- Nothing computes until an eval (or implicit eval: `print`, `.item()`, memory access,
  `save`). Eval at coarse boundaries (once per generation step/iteration), never in a hot
  inner loop.
- Prefer `asyncEval` to overlap compute with the next graph build. There is no
  `asyncEval(MLXArray...)` variadic — use the collection or `Any...` form.

## Determinism for tests
- Seed: `MLXRandom.seed(_:)`. Sampling: `temperature: 0`. Then generation is reproducible
  enough to assert on. Keep all randomness seeded in integration tests.
- Unit tests use a mock `LanguageModel` and never touch MLX — fully deterministic.
