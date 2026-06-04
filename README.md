# coscientist-mlx

A native **Swift + MLX** port of [AI-CoScientist](https://github.com/The-Swarm-Corporation/AI-CoScientist):
a multi-agent pipeline that generates, peer-reviews, ranks (via Elo tournaments), and
iteratively evolves scientific research hypotheses — running **local open models on Apple
Silicon**, fully offline.

> Status: **M2 — schema-constrained decoding.** M0 foundation + M1 MLX inference adapter
> (`MLXLanguageModel`, local models on Apple Silicon) + M2 schema-driven decoding
> (typed `JSONSchema` per agent output, prompt injection, validation, repair-retry). The
> agent engine lands in M4. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full
> design and milestones, [`docs/MODELS.md`](docs/MODELS.md) for the open-model survey
> and tiered recommendations, and [`docs/IOS.md`](docs/IOS.md) for on-device iPhone/iPad
> enablement.

## Why a port

The Python original calls hosted LLM APIs and assumes the model returns valid JSON. This
port targets Apple Silicon with [MLX](https://github.com/ml-explore/mlx-swift): local,
private, zero marginal cost — and aims to be *superior* via embedding-based proximity
clustering, schema-constrained decoding, and batched inference. See the architecture doc.

## Requirements

- macOS 14+ on Apple Silicon
- Swift 6 toolchain (Xcode 26+)

## Build & test

```bash
swift build
swift test
```

## Engineering standards

This is a public project built to the team's cardinal values: **Clean Code, Clean
Architecture, SOLID, and genuine TDD/BDD.** Concretely:

- The domain/engine depends only on protocols (`LanguageModel`, `StructuredDecoder`,
  `EmbeddingModel`); every `import MLX*` is quarantined in the adapter layer.
- Behaviour is driven by tests written first; unit tests use a mock backend (no GPU, no
  downloads). Real-model runs live in a separate, opt-in integration target.
- MLX-Swift specifics are captured, source-verified, in
  [`.claude/skills/mlx-swift`](.claude/skills/mlx-swift/SKILL.md).

## Layout

```
Sources/AICoScientistKit/   Core, Inference, Embeddings, Agents, Engine, Support
Sources/AICoScientistCLI/   aicoscientist command-line driver
Tests/                      test-first specs
docs/ARCHITECTURE.md        design, mapping from the Python reference, milestones
```

## License

TBD before public release.
