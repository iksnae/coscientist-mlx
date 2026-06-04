# Models & Devices

Which open models to run for each role, and what fits on a Mac versus an iPhone or iPad.

## Overview

The kit is model-agnostic — it talks to ``LanguageModel`` and ``EmbeddingModel``. The
recommendations below (snapshot mid-2026) are what the MLX adapter loads by default and
what the model survey validates. The full survey, with Hugging Face repo ids and
verification notes, lives in
[`docs/MODELS.md`](https://github.com/iksnae/coscientist-mlx/blob/main/docs/MODELS.md)
and [`docs/IOS.md`](https://github.com/iksnae/coscientist-mlx/blob/main/docs/IOS.md).

## Recommended lineup (text-only `mlx-lm` path)

| Tier | RAM | Model | Why |
|---|---|---|---|
| Small | 16 GB | Qwen3-4B-Instruct-2507 (4-bit) | Project default; cleanest JSON for judge/scorer roles |
| Mid | 32 GB | Qwen3-8B (4-bit DWQ) | Hybrid reasoning on the plain LLM path |
| Large | 64 GB+ | Qwen3.6-35B-A3B (MoE) | 35B-class quality at ~3B active; long context |

**Role-aware split:** use *instruct, non-thinking* models for schema-critical roles
(reflection, ranking, tournament) so there is no `<think>` block to strip, and
*thinking-capable* models for generation and evolution where reasoning lifts quality.
Per-role routing is wired through ``RoleDecoderRouter`` / ``DecoderRouting``.

**Embeddings:** `Qwen3-Embedding-0.6B` (4-bit) is the default for
``EmbeddingProximityAnalyzer`` — small, top-tier on MTEB, and one of only three
architectures the MLX-Swift embedding registry supports.

> Don't quantize schema-critical roles below 4-bit: JSON/tool-call reliability degrades
> before chat quality does. 4-bit is the floor.

## On-device (iOS / iPadOS)

MLX-Swift runs on iOS 17+ and the full stack has been measured generating a hypothesis
**fully on-device** (iPhone 15 Pro, Qwen3-1.7B, ~22 tok/s). The binding constraints are
per-app RAM and thermal throttling, not compute:

- **The phone tier is sub-4B 4-bit.** An 8 GB iPhone realistically gives ~5–6 GB usable
  with the increased-memory entitlement → comfortable to 3–4B + the 0.6B embedder.
- **Don't run the full 7-agent loop on a phone.** The `3·N` tournament is exactly the
  sustained load thermal throttling punishes. Go **hybrid**: on-device generation +
  embedding proximity, and offload reflection/tournament to a hosted model via the
  `AICoScientistRemote` adapter, routed per stage through ``DecoderRouting`` /
  ``RoleDecoderRouter`` — no engine changes required.
- **Inference is foreground-only** — backgrounded Metal work is killed by iOS.

See [`docs/IOS.md`](https://github.com/iksnae/coscientist-mlx/blob/main/docs/IOS.md) for
device memory tables, the entitlement name, and the GPU cache-limit tuning knob.
