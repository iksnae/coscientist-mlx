# Structured (JSON-schema-constrained) output

The reference Python implementation depends on the LLM returning valid JSON and parses it
best-effort (`_safely_parse_json` + regex). Local 3B–8B models break this constantly. The
correct, hardest-but-right approach is **constrained decoding**: make invalid tokens
impossible, then decode straight into `Codable` structs.

## Architecture (DIP — keep it swappable)

Define a protocol the engine depends on; never let the engine import MLX or a grammar lib:

```swift
public protocol StructuredDecoder: Sendable {
    func decode<T: Decodable & Sendable>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T
}
```
Implementations (most → least rigorous), all behind that protocol:
1. `ConstrainedDecoder` — grammar/logit-masked decoding (preferred).
2. `RepairRetryDecoder` — prompt + tolerant parse + one error-fed retry (fallback).
3. `MockStructuredDecoder` — returns canned JSON for unit tests.

## Option 1 — `mlx-swift-structured` (XGrammar)

Swift-native, integrates with `mlx-swift-lm`'s `TokenIterator`. **Caveat: v0.1.0, single
maintainer** — acceptable only behind `StructuredDecoder`. Reported overhead <10%.

```swift
// .package(url: "https://github.com/petrukha-ivan/mlx-swift-structured", from: "0.1.0")
import MLXStructured

let schema = JSONSchema.object(
    description: "Tournament verdict",
    properties: ["winner": .string(), "rationale": .string()],
    required: ["winner", "rationale"]
)
let result = try await generate(            // MLXStructured overload
    input: input, context: context,
    schema: schema, generating: TournamentJudgment.self
)
```
Manual wiring (confirms upstream `TokenIterator` integration):
```swift
let grammar = try Grammar.schema(schema)         // also: .generable(_:), .regex(_:), .ebnf(_:)
let processor = try await GrammarMaskedLogitProcessor.from(
    configuration: context.configuration, grammar: grammar)
let iterator = try TokenIterator(
    input: input, model: context.model,
    processor: processor, sampler: sampler, maxTokens: 256)
```

## Option 2 — hand-rolled `LogitProcessor`

If you avoid the 0.1.0 dependency, implement masking yourself against the confirmed
`MLXLMCommon` protocol:
```swift
public protocol LogitProcessor {
    mutating func prompt(_ prompt: MLXArray)
    func process(logits: MLXArray) -> MLXArray   // set disallowed token logits to -Float.infinity
    mutating func didSample(token: MLXArray)
}
```
Drive it through the `TokenIterator(... processor:sampler: ...)` overload. Even minimal
JSON-structural masking (only legal next characters) hugely improves reliability. Note:
`process` runs per step on `MLXArray` — stays inside the model's isolation; return an
`MLXArray`, never let it escape `perform`.

## Schema from Codable — `swift-json-schema`

```swift
// .package(url: "https://github.com/ajevans99/swift-json-schema", from: "0.4.0")
import JSONSchema
import JSONSchemaBuilder

@Schemable
struct ReviewScores: Codable, Sendable {
    let scientificSoundness: Double
    let novelty: Double
    let testability: Double
    let impact: Double
}
// ReviewScores.schema  → a JSONSchema you feed to Grammar.schema(_:)
// schema.validate(instance:) → runtime validation for the fallback path
```
`@ObjectOptions(.additionalProperties { false })` tightens objects. This is the bridge:
one `@Schemable @Codable` type → constrained grammar → decoded value. No duplicate schema.

## Option 3 — fallback ladder (always present)

For any model/config without a working grammar, degrade gracefully — but never silently:
1. Prompt: "Respond with ONLY a JSON object matching this schema: …".
2. Tolerant extract: strip ```` ```json ```` fences; take first balanced `{ … }`.
3. `JSONDecoder().decode(T.self, …)`.
4. On `DecodingError`: feed the error message back once ("Your JSON was invalid: <err>.
   Return corrected JSON only.") and retry.
5. Still failing → throw a typed `AgentError.decodingFailed`, recorded in
   `WorkflowResult.errors`. The engine continues; it does not crash.

## Testing (TDD)

- Unit-test each agent's decode path with `MockStructuredDecoder` returning fixed JSON —
  no model, deterministic, fast.
- Property-test the fallback parser with malformed/fenced/truncated inputs.
- One opt-in integration test asserts a real model + constrained decoder yields a value
  that `schema.validate` accepts.

## Uncertainties
- `mlx-swift-structured` API quoted from its README; pin and re-verify `Grammar`,
  `GrammarMaskedLogitProcessor`, and the `generate(... schema: generating:)` overload.
- `swift-json-schema` version `0.4.0` is indicative — check the latest tag.
