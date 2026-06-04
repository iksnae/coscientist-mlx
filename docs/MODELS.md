# Model Research — Open Models for the MLX Pipeline

> Snapshot: **June 2026**, project status **M0**. This is research to inform the model
> registry that lands with inference (M1) and structured decoding (M2). Repo ids marked
> ⚠️ are *inferred from collections, not yet confirmed on Hugging Face* — verify before
> pinning in code. See [`ARCHITECTURE.md`](ARCHITECTURE.md) §3 (inference), §6 (proximity).

## TL;DR

- **Every current default is a generation behind.** The M0 placeholders
  (`Qwen2.5-7B`, `Llama-3.1-8B`, `Llama-3.2-3B`, `Phi-3.5-mini`, `Mistral-7B-v0.3`,
  `gemma-3-1b`) predate the Qwen3 / Qwen3.5 / Qwen3.6, Gemma 4, and Llama 4 releases.
  M1 is the cheap moment to reset the registry — nothing is wired in yet.
- **Stay on the text-only `mlx-lm` path.** The newest Qwen3.5/3.6 *dense* models and
  *all* Gemma 4 models are natively multimodal and load via **`mlx-vlm`** — a different
  code path. Prefer **text-only Qwen3 instruct** + the **Qwen3.6 MoE** line.
- **Keep the embedder.** `mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ` is still the right
  default; the MLX-Swift embedding registry only supports 3 architectures, which is the
  binding constraint.
- **Constrained decoding has exactly one native option** (`mlx-swift-structured`,
  v0.1.0) — pin a commit and keep the repair-retry fallback ladder.

## 1. Integration gotchas (these drive selection)

1. **VLM vs LLM load path.** Qwen3.5/3.6 *dense* and all Gemma 4 repos load via
   `mlx-vlm`, not `mlx-lm`. To keep `import MLX*` confined to the text-LLM adapter,
   choose text-only Qwen3 instruct or the Qwen3.6 **MoE** (confirmed text-only).
2. **No more `/nothink` token.** Qwen3.5/3.6 default thinking to *on*; it is toggled via
   `chat_template_kwargs={"enable_thinking": false}`. The per-agent prompt plumbing must
   pass that flag rather than inject a `/nothink` token.
3. **Don't sub-4-bit schema-critical roles.** JSON/tool-call reliability degrades
   *before* chat quality as you quantize down. 4-bit is the floor for judge/scorer roles.

## 2. Recommended LLM lineup (all text-only `mlx-lm`)

| Tier | RAM | Model | Repo id | Why |
|---|---|---|---|---|
| **Small** | 16 GB | Qwen3-4B Instruct | `mlx-community/Qwen3-4B-Instruct-2507-4bit` | Beats the 7B default at ~half size; instruct = no `<think>` to strip → cleanest JSON for judge/scorer roles |
| Small (fan-out) | 16 GB | Qwen3-1.7B | `mlx-community/Qwen3-1.7B-4bit-DWQ` | Cheap judge for the 3·N tournament fan-out |
| **Mid** | 32 GB | Qwen3-8B | ⚠️ `mlx-community/Qwen3-8B-4bit-DWQ` | Hybrid reasoning on the plain LLM path; safest 32 GB pick |
| Mid (ceiling) | 32 GB | Qwen3-14B | ⚠️ `mlx-community/Qwen3-14B-4bit-DWQ` | ~9 GB @ 4-bit; stronger generation if RAM allows |
| **Large** ⭐ | 64 GB+ | Qwen3.6-35B-A3B (MoE) | `mlx-community/Qwen3.6-35B-A3B-4bit-DWQ` | Standout: 35B-class quality at **3B active** → fast; hybrid thinking; 262K ctx; Apache-2.0; text-only confirmed |
| Large (alt quant) | 64 GB+ | Qwen3.6-35B-A3B | `unsloth/Qwen3.6-35B-A3B-UD-MLX-4bit` · `mlx-community/Qwen3.6-35B-A3B-OptiQ-4bit` | Dynamic / sensitivity-aware quants — A/B for judge accuracy |
| Large (long-doc) | 64 GB+ | Llama-4-Scout (MoE) | `mlx-community/Llama-4-Scout-17B-16E-Instruct-4bit` | Up to 10M ctx for long-doc review; weaker reasoning, heavier RAM than Qwen3.6-MoE |

**Out of scope at ≤64 GB:** `Qwen3-235B-A22B` (~130 GB @ 4-bit, needs 128 GB+),
`DeepSeek-V4-Flash/Pro`.

### Role-aware split

Your seven roles want different things ([`ARCHITECTURE.md`](ARCHITECTURE.md) §5):

- **Reflection / Ranking / Tournament judges** → *instruct, non-thinking*
  (`Qwen3-4B-Instruct-2507`). Bulletproof JSON, no reasoning tokens to parse out.
- **Generation / Evolution** → *thinking-capable* (`Qwen3.6-35B-A3B` or `Qwen3-8B`).
  Reasoning lifts hypothesis quality.

### Verdict vs. current defaults

| M0 default | Replace with |
|---|---|
| `Qwen2.5-7B-Instruct-4bit` | `Qwen3-4B-Instruct-2507-4bit` (smaller, smarter) or `Qwen3-8B-4bit-DWQ` |
| `Meta-Llama-3.1-8B-Instruct-4bit` | `Qwen3-8B-4bit-DWQ` (Llama 3.1 is 2+ gens behind) |
| `Llama-3.2-3B` / `Phi-3.5-mini` / `Mistral-7B-v0.3` | `Qwen3-4B-Instruct-2507` |
| `gemma-3-1b-it-qat-4bit` | `Qwen3-1.7B-4bit-DWQ` (adds reasoning mode) |

## 3. Embeddings (Proximity, M5)

The **MLX-Swift embedding registry supports only 3 architectures** (`bert`,
`nomic_bert`, `qwen3`) — this is the constraint, not MTEB scores. The Python
`mlx-embeddings` library supports more, but that does not help a Swift app.

| Role | Repo id | Dims | Max seq | MTEB tier | Swift support |
|---|---|---|---|---|---|
| **Default (keep)** | `mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ` | 1024 (MRL 32–1024) | 32K | Eng v2 ~70.7 | ✅ `qwen3` |
| Fast/small toggle | `BAAI/bge-small-en-v1.5` | 384 | 512 | ~62 | ✅ `bert` |
| Long hypotheses | `nomic-ai/nomic-embed-text-v1.5` | 768 (MRL→64) | 8192 | ~62–63 | ✅ `nomic_bert` |
| Upgrade ceiling | ⚠️ `mlx-community/Qwen3-Embedding-4B-4bit-DWQ` | 2560 | 32K | Eng v2 ~74.6 | ✅ `qwen3` (confirm repo) |

- **Verdict: keep `Qwen3-Embedding-0.6B-4bit-DWQ`.** It's the only registry model in the
  top MTEB tier while staying tiny; 32K ctx + MRL (truncate to 256/512 dims for faster
  cosine) are real wins for clustering.
- ⚠️ **EmbeddingGemma-300M** — the tempting 2026 SOTA-for-size — is **blocked**: Gemma3
  arch, absent from the Swift registry. Usable only if you port the architecture.

## 4. Structured / constrained JSON decoding (M2)

- **`mlx-swift-structured`** (`github.com/petrukha-ivan/mlx-swift-structured`) is the
  *only* native fit — a Swift XGrammar binding with a `GrammarMaskedLogitProcessor` that
  plugs into the mlx-swift-lm sampler, plus JSON-Schema → grammar
  (`Grammar.schema()`). **But it's v0.1.0 (Apr 2026), self-described "early stage."**
  → **Pin a commit; keep the repair-retry fallback ladder** ([`ARCHITECTURE.md`](ARCHITECTURE.md)
  §3). There is no official XGrammar Swift binding; the only alternative is bridging
  XGrammar's C++ API yourself.
- **Upstream to track:** XGrammar-2 (May 2026) adds "Structural Tags" that natively model
  a *reasoning channel → tool-call channel* for known models — but it has no Swift binding
  yet (Python/C++/Rust/JS only).
- **Thinking models + constrained JSON → two-stage decoding.** Generate
  `<think>…</think>` freeform, stop at `</think>`, *then* attach the grammar processor
  reusing the KV cache. We control the `TokenIterator`, so this is clean to implement.
- **Schema design:** order *reasoning/explanation fields before score fields* so the
  model reasons before committing a judgment. Keep enums and `minItems`/`maxItems`
  constraints lean — heavy grammars blow up compile time.
- **Caveat (BAML):** constrained decoding guarantees *structural* validity, not *semantic*
  correctness. Keep schema validation + retry even with it.

### Model families for clean JSON / tool calls

Qwen3 (incl. Qwen3-Coder) and Gemma 3/4 have native function-calling tuning and emit
clean JSON; they are the pragmatic sweet spot at Apple-Silicon sizes. For our schema-
critical judge/scorer roles, prefer **Qwen3 instruct (non-thinking)** so there is no
`<think>` block to strip before parsing.

## 5. Verification queue (before pinning in code)

- [ ] Confirm exact repo ids: `Qwen3-8B-4bit-DWQ`, `Qwen3-14B-4bit-DWQ`,
  `Qwen3-Embedding-4B-4bit-DWQ` (date-stamped DWQ suffixes exist, e.g. `-053125`).
- [ ] Confirm `Qwen3.6-35B-A3B-4bit-DWQ` disk size (~20.7 GB reported) against target RAM
  headroom with embedder + KV cache resident.
- [ ] Re-check `mlx-swift-structured` version/commit against the repo before building M2 on it.

## Sources

- [huggingface.co/mlx-community](https://huggingface.co/mlx-community) ·
  [Qwen3.6-35B-A3B-4bit-DWQ](https://huggingface.co/mlx-community/Qwen3.6-35B-A3B-4bit-DWQ) ·
  [Qwen3-Embedding paper](https://arxiv.org/abs/2506.05176)
- [mlx-swift-lm embeddings reference](https://github.com/ml-explore/mlx-swift-lm/blob/main/skills/mlx-swift-lm/references/embeddings.md)
- [mlx-swift-structured](https://github.com/petrukha-ivan/mlx-swift-structured) ·
  [XGrammar](https://github.com/mlc-ai/xgrammar) ·
  [XGrammar-2 (May 2026)](https://blog.mlc.ai/2026/05/04/xgrammar-2-fast-customizable-structured-generation)
- [BAML — Structured Outputs Create False Confidence](https://boundaryml.com/blog/structured-outputs-create-false-confidence)
