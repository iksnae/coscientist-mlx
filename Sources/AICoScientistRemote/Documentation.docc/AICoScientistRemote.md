# ``AICoScientistRemote``

A hosted, OpenAI-compatible `LanguageModel` adapter — for the hybrid split where some
stages run on a strong remote model while the rest stay on-device.

## Overview

``RemoteLanguageModel`` conforms to `AICoScientistKit.LanguageModel` by calling an
OpenAI-compatible **Chat Completions** endpoint (OpenAI, OpenRouter, or any local
server that speaks the same API). It has **no MLX dependency** — only Foundation — so it
links cleanly into any platform, including alongside the on-device MLX adapter.

This is the seam that makes the *hybrid* architecture practical: an 8 GB iPhone can run
generation and embedding-proximity locally while offloading the sustained-load
tournament and reflection stages to a hosted judge, routed per stage through
`AICoScientistKit`'s `DecoderRouting`.

```swift
import AICoScientistKit
import AICoScientistMLX
import AICoScientistRemote

let local = SchemaConstrainedDecoder(model: try await MLXLanguageModel.load())
let remote = SchemaConstrainedDecoder(model: RemoteLanguageModel(model: "gpt-4o"))

// Generation/evolution stay local; reflection + tournament go to the remote judge.
let router = RoleDecoderRouter(
    default: local,
    overrides: [.reflection: remote, .tournament: remote]
)
let engine = CoScientistEngine(router: router)
```

The API key defaults to `OPENAI_API_KEY` from the environment; the base URL defaults to
OpenAI's `/v1` and can be pointed at any compatible server.

### Testability

Networking sits behind the ``HTTPTransport`` protocol (default ``URLSessionTransport``),
so ``RemoteLanguageModel`` is unit-testable with a stub transport — no live HTTP — in the
same DIP spirit as the rest of the codebase.

## Topics

### Remote Model

- ``RemoteLanguageModel``

### HTTP Transport

- ``HTTPTransport``
- ``URLSessionTransport``
