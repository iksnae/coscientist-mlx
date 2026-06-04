# iOS / iPadOS Enablement — Research & Plan

> Snapshot: **June 2026**. Companion to [`MODELS.md`](MODELS.md) (the model survey) and
> [`ARCHITECTURE.md`](ARCHITECTURE.md) (the layering this builds on). Repo ids / figures
> marked ⚠️ are not primary-verified — confirm on target hardware before relying on them.

## TL;DR

- **MLX-Swift runs on iOS 17+ today.** It's not a compute problem — the LLMEval example
  ships on iPhone. The binding constraint is **per-app RAM** and, for any multi-call loop,
  **thermal throttling**.
- **The phone tier is sub-4B 4-bit.** An 8 GB iPhone with the increased-memory entitlement
  realistically gives ~5–6 GB usable → comfortable up to **3–4B 4-bit** + the 0.6 B
  embedder. A 16 GB iPad Pro can host 7–8 B.
- **Don't run the full 7-agent loop on a phone.** Tournament alone is 3·N sequential judge
  calls — exactly the sustained load thermal throttling punishes, at the quality floor where
  tiny judges degrade. Go **hybrid**: on-device single-pass generation + embedding proximity;
  offload the heavy tournament/ranking stages.
- **The existing layering already supports this.** `AICoScientistKit` defines the protocol
  boundary with no MLX import; an iOS app target links `AICoScientistMLX` (on-device adapter)
  and/or a remote adapter behind the same `LanguageModel` protocol, routed per stage.

## 0. Measured on device ✅ (iPhone 15 Pro, A17 Pro, 8 GB, iOS 26.5)

Verified June 2026 with the `CoScientistApp` spike (`ios/App`, generated via `project.yml`):
the full MLX stack builds for iOS arm64, installs, and runs — AI-CoScientist generates a
hypothesis **fully on-device**. Single-generation probe, `Memory.cacheLimit = 20 MB`, **no**
increased-memory entitlement:

| Metric | Measured | Implication |
|---|---|---|
| Model | `Qwen3-1.7B-4bit` | runs comfortably |
| Latency / speed | 1.4 s · **~22 tok/s** | A17 Pro is *below* the ~40–60 tok/s A18/A19 estimate — a 3·N tournament on-device would be slow → **offload heavy stages** |
| App memory budget | **~3.3 GB** available (no entitlement) | the default jetsam budget on this 8 GB phone |
| Memory after 1.7B load+gen | 3357 → **2274 MB** free (~1.1 GB consumed) | **Qwen3-4B (~2.3 GB) + KV + embedder will NOT fit safely without the increased-memory entitlement** — 1.7B is the safe default; 4B needs the entitlement |
| Thermal | nominal → **fair after a single generation** | confirms sustained loops throttle; don't run the full pipeline on-device |
| Output quirk | Qwen3-1.7B emitted an empty `<think></think>` before the answer | thinking model — set `enable_thinking:false` / use instruct models for schema-critical roles (the tolerant JSON extractor handled it) |

Bottom line: **on-device generation is real and viable at ≤2B**; the hybrid split (local
generation + embeddings, offload tournament/ranking/evolution) is the right architecture,
now empirically grounded. Build/install: see `.claude/skills/mlx-swift` (xcodebuild +
`-skipMacroValidation` + `-allowProvisioningUpdates`; Metal toolchain + iOS platform required).

## 1. Does MLX-Swift run on iOS? Yes — iOS 17+

- `mlx-swift` `Package.swift` declares `.iOS(.v17)` (also tvOS/visionOS 17, macOS 14).
  `mlx-swift-lm` rides the same floor. **Minimum iOS is 17.**
- **No Simulator** — the iOS Simulator doesn't expose the Metal features MLX needs; **test
  on a physical device.**
- Shipping prior art: `ml-explore/mlx-swift-examples` → `Applications/LLMEval` and
  `MLXChatExample` (iOS + macOS); awni's "run an LLM on an iPhone with MLX Swift" gist;
  third-party `SharpAI/SwiftLM`.
- **Our gap:** `Package.swift` is `platforms: [.macOS(.v14)]` and the driver is a CLI
  executable (`aicoscientist`) — CLI executables don't deploy to iOS. iOS needs `.iOS(.v17)`
  added and an **app target** linking `AICoScientistMLX`. The Kit/MLX split already in place
  is exactly the right shape for this.

## 2. Memory — the hard constraint

- iOS jetsam kills an app at roughly **~50% of device RAM** by default. There is **no public
  Apple per-device table** — the only authoritative runtime source is
  `os_proc_available_memory()`. **Gate model choice on it at launch.**
- **Entitlement (exact name):** `com.apple.developer.kernel.increased-memory-limit`
  (Boolean). Raises the ceiling on supported devices/OS only; the grant is **not guaranteed**
  and varies with total RAM and system pressure.

| Device | Total RAM | Default app limit | With entitlement |
|---|---|---|---|
| iPhone 15 / 16 (non-Pro) | 8 GB | ~4 GB | ~5–6 GB |
| iPhone 16 Pro / 17 | 8–12 GB | ~4 GB | ~6 GB+ |
| iPad Pro M4 (≤512 GB) | 8 GB | ~4 GB | ~6 GB |
| iPad Pro M4 (1–2 TB) | 16 GB | ~5 GB | ~12 GB |

⚠️ **Per-GB figures are aggregated from developer forums/press, not an Apple spec** — verify
on-target via `os_proc_available_memory()`.

**4-bit footprints (weights only; add KV cache + ~0.5–1.5 GB framework overhead):**
1B ≈ 0.6–0.8 GB · 3B ≈ 1.8–2.2 GB · 4B ≈ 2.3–2.8 GB · 7–8B ≈ 4.3–4.8 GB.
→ **8 GB iPhone (~5–6 GB budget): comfortable to 3–4B; 7–8B is borderline** once KV cache +
a co-resident embedder are added. **16 GB iPad Pro: 7–8B comfortable.**

## 3. On-device model shortlist

Cross-references [`MODELS.md`](MODELS.md) §2; these are the subset that fits a phone.

| Rank | Model | Repo id | Weights @4-bit | Reasoning | Notes |
|---|---|---|---|---|---|
| **1 (8 GB)** | Qwen3-4B Instruct-2507 | `mlx-community/Qwen3-4B-Instruct-2507-4bit-DWQ-2510` (plain: `…-4bit`) | ~2.2–2.4 GB | no (instruct) | Best JSON adherence at this size; reserve for newer 8 GB devices. Thinking variant: `Qwen3-4B-Thinking-2507`. |
| **2 (broad floor)** | LFM2.5-1.2B-Thinking | ⚠️ `LiquidAI/LFM2.5-1.2B-Thinking-MLX-4bit` | **628 MB** | yes (native `<think>`) | Only sub-1 GB reasoner; fastest measured on-device. **Quirk: defaults to *Pythonic* tool calls, not JSON** — force JSON in the system prompt or use constrained decoding. |
| 3 | Qwen3-1.7B | `mlx-community/Qwen3-1.7B-4bit` | ~984 MB | yes (hybrid) | Best JSON in sub-2B class; notable throughput drop on long prompts. |
| 4 | Llama-3.2-3B Instruct | `mlx-community/Llama-3.2-3B-Instruct-4bit` | ~1.8 GB | no | Proven/fast but ~3B@Q4 starts to hallucinate; weaker format adherence than Qwen3. |
| 5 (fallback) | Llama-3.2-1B Instruct | `mlx-community/Llama-3.2-1B-Instruct-4bit` | ~713 MB | no | Cheap pairwise-judge fallback only. |

**Avoid on phone:** Phi-4-mini (3.8 B, *not* "mini" in footprint; reasoning variant is
math-specialized), Gemma 3 1B/270M (too weak for reliable scientific JSON; 1B-QAT was the
*slowest* on-device), Gemma 3 4B+ (VLM → `mlx-vlm` path). SmolLM3-3B: JSON reliability at
4-bit unverified.

**Embedder:** `mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ` (~300 MB) stays co-resident
fine. ⚠️ One open issue reports unbounded memory growth on repeated embedding inference with
this variant — clear caches between batches and watch for a leak.

**Speed:** ~40–60 tok/s for 1.7–4B on A18/A19; M4 iPad meaningfully faster (LFM2.5 hit
~124 tok/s on iPad). Prefer **DWQ builds over plain `-4bit`** and keep **KV cache at 8-bit+**
— low-bit KV cache degrades structured output first.

## 4. Practical gotchas (the ones that kill you)

- **GPU/Metal cache cap — the #1 tuning knob.** Set the GPU cache limit low (LLMEval uses
  20 MB on iOS) so the framework doesn't hoard buffers and trip jetsam. In current mlx-swift
  the API is **`Memory.cacheLimit = 20 * 1024 * 1024`** (`MLX.GPU.set(cacheLimit:)` is
  deprecated — see `.claude/skills/mlx-swift/references/memory-and-perf.md`).
- **Background = hard kill.** iOS forbids creating a Metal compute context in the background;
  backgrounded GPU work throws `IOGPUMetalError: Insufficient Permission` and crashes.
  **Inference is foreground-only** — checkpoint/pause on `scenePhase` change. A long
  autonomous run won't survive the user switching apps.
- **Thermal throttling is the real ceiling for pipelines.** Sustained generation throttles
  after ~60–90 s, dropping ~40–60 % token rate. Monitor
  `ProcessInfo.processInfo.thermalState` and back off. Dozens of sequential agent calls run
  hot and slow sharply.
- **Models aren't bundled** (App Store size + practical weight). First-launch download from
  Hugging Face (0.6 B embedder ~0.9 GB on disk; 3–4B generator ~2–3 GB). Needs **Outgoing
  Connections (Client)** capability and a first-run flow: progress, Wi-Fi gating,
  resumable background `URLSession`, on-device storage management.

## 5. Architecture implication — go hybrid, route per stage

Running the **entire** pipeline on a phone is not advisable: the 3·N tournament + multi-round
reflection/evolution is exactly the sustained-load pattern thermal throttling punishes, the
fitting models (1.7–4B) are weak judges, and foreground-only execution can't survive
backgrounding.

**Recommended shape:**
- **On-device (offline, private, interactive):** single-pass generation + the
  embedding-proximity / dedup stage, using a 3–4B 4-bit generator + Qwen3-Embedding-0.6B.
  Embeddings are cheap and a natural on-device fit.
- **Offload heavy stages** (tournament = 3·N judge calls, ranking, multi-round
  reflection/evolution) to a server/cloud model — live when on Wi-Fi + power, or as a
  deferred batch job.
- **Implementation:** supply an on-device `MLX` adapter and a remote adapter behind the same
  `LanguageModel` protocol; route per stage. This is the DIP the layering already enables —
  no engine changes.

**Prior art:** fully on-device multi-agent loops are still rare in mid-2026; the documented
production pattern is a **tiered inference strategy** (small fast on-device tier +
escalation). Treat an unattended on-device tournament as research, not a shipping default.

## 6. Concrete next steps (when iOS work starts)

- [ ] Add `.iOS(.v17)` to `Package.swift` platforms; add an iOS **app target** linking
  `AICoScientistMLX` (CLI stays macOS-only).
- [ ] Request `com.apple.developer.kernel.increased-memory-limit`; at launch read
  `os_proc_available_memory()` and pick the model tier from it.
- [ ] Set `MLX.GPU.set(cacheLimit:)`; handle `scenePhase`/`thermalState`; foreground-gate
  inference.
- [ ] First-run model download flow (resumable background `URLSession`, Wi-Fi gate, progress).
- [ ] Add a **remote `LanguageModel` adapter** + per-stage routing policy for the hybrid split.
- [ ] Verify ⚠️ repo ids on Hugging Face: `Qwen3-4B-Instruct-2507-4bit-DWQ-2510`,
  `LiquidAI/LFM2.5-1.2B-Thinking-MLX-4bit`.

## Sources

- [mlx-swift Package.swift (iOS 17+)](https://github.com/ml-explore/mlx-swift/blob/main/Package.swift) ·
  [LLMEval (iOS)](https://github.com/ml-explore/mlx-swift-examples/blob/main/Applications/LLMEval/README.md) ·
  [awni iPhone+MLX gist](https://gist.github.com/awni/fe4f96c21ead68e60191190cbc1c129b)
- [increased-memory-limit entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.kernel.increased-memory-limit) ·
  [iPadOS 12 GB grant](https://www.macrumors.com/2021/09/17/ipados-15-up-to-12gb-ram-high-end-ipad-pro/)
- [iOS LLM runtime benchmark (MLX fastest)](https://rockyshikoku.medium.com/local-llm-on-iphone-which-runtime-is-actually-fastest-58096685481e) ·
  [iPhone 17 / iPad MLX benchmark](https://rickytakkar.com/blog_russet_mlx_benchmark.html) ·
  [tiered inference strategy](https://medium.com/@nnrajesh3006/the-tiered-inference-strategy-solving-the-ios-llm-background-crash-7e1195453188)
- [LFM2.5-1.2B-Thinking (MLX 4-bit)](https://huggingface.co/LiquidAI/LFM2.5-1.2B-Thinking-MLX-4bit) ·
  [Qwen3-4B-Instruct-2507-4bit-DWQ-2510](https://huggingface.co/mlx-community/Qwen3-4B-Instruct-2507-4bit-DWQ-2510)
