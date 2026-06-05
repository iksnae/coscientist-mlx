# Spike: Distributed cross-device compute for CoScientist

Status: Complete (research). Date: 2026-06-05. Milestone: M18.

## Question

Can CoScientist harness Apple Silicon **across the user's iCloud-connected
devices** (Mac + iPad + iPhone) to run a study's model inference
distributed — and if so, how? The operator's framing was "the capability
Apple released for sharing compute resources across your iCloud connected
devices."

## Verdict (TL;DR)

- **A first-party "share compute across your iCloud devices" API does not
  exist** for third-party apps. The premise conflates three real but
  different Apple features (Private Cloud Compute, iCloud/CloudKit sync,
  Continuity) — none of which expose general cross-device compute to apps.
- **True distributed inference** (one model's layers split across
  Mac+iPad+iPhone, all participating in every forward pass) is **not
  practical today.** Apple's MLX distributed support is real but
  Mac-and-interconnect oriented; iPhone/iPad are not viable distributed
  nodes.
- **Feasible and recommended: local-network *offload*.** Run an
  OpenAI-compatible model server on the Mac and have the iPhone/iPad use it
  via the existing `RemoteLanguageModel` seam (M7), discovered on the LAN
  via **Bonjour / `NetworkBrowser`** (or the new Wi-Fi Aware transport).
  This achieves the operator's actual goal — a phone/tablet harnessing the
  Mac's Apple Silicon — and reuses code we already have. Drafted as **M19**.

## API survey

### 1. Is there a first-party cross-device compute API? — No

- **Private Cloud Compute (PCC)** runs Apple Intelligence requests on
  *Apple's own servers*, not on the user's other devices, and is a
  system/Apple-Intelligence feature — not a general third-party compute
  API.
  [Apple Security Research](https://security.apple.com/blog/private-cloud-compute/),
  [Apple Newsroom, WWDC 2025](https://www.apple.com/newsroom/2025/06/apple-intelligence-gets-even-more-powerful-with-new-capabilities-across-apple-devices/).
- **Foundation Models framework** (WWDC 2025) gives apps the *on-device*
  model only; "more complex requests" escalate to PCC, again Apple-managed,
  not your devices.
  [Meet the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2025/286/).
- **iCloud / CloudKit** share *data*, not compute.
  [CloudKit](https://developer.apple.com/icloud/cloudkit/).
- No Apple documentation or session describes an app-usable API to
  distribute arbitrary computation across a user's devices.
  [Configuring iCloud services](https://developer.apple.com/documentation/xcode/configuring-icloud-services).

Conclusion: the "compute sharing across iCloud devices" capability, as a
public third-party API, **is not available**.

### 2. Device-to-device transport that *does* exist (the building block)

The relevant new primitives (iOS/iPadOS/macOS 26, WWDC 2025) are
**networking**, not compute-distribution:

- **Wi-Fi Aware framework** — infrastructure-free, authenticated,
  encrypted, high-throughput, low-latency peer-to-peer between Apple
  devices, third-party devices, and accessories.
  [Wi-Fi Aware docs](https://developer.apple.com/documentation/WiFiAware),
  [WWDC25 228](https://developer.apple.com/videos/play/wwdc2025/228/).
- **Network framework `NetworkBrowser`** — discovers nearby endpoints via
  **Bonjour** or Wi-Fi Aware; the modern way to find a peer service on the
  LAN.
  [Use structured concurrency with Network framework, WWDC25 250](https://developer.apple.com/videos/play/wwdc2025/250/).
- **DeviceDiscoveryUI** — system pairing UI for app-to-device connections.

These give us a clean, encrypted way for an iPhone/iPad to *find and reach*
a Mac on the same network — but we still define the workload protocol
ourselves.

### 3. True distributed inference (MLX) — real, but Mac-oriented

- **MLX `mlx.distributed`** splits a single model's layers across machines
  so all ranks participate in each forward pass — **ring** backend
  (TCP/MPI) and, from **macOS 26.2**, **JACCL** (tensor parallelism over
  Thunderbolt 5 RDMA, ~an order of magnitude lower latency than ring).
  [MLX Distributed Communication](https://ml-explore.github.io/mlx/build/html/usage/distributed.html).
- Practical setups are **Macs linked by Thunderbolt 5 or fast Ethernet**;
  third-party **Exo** does heterogeneous Apple-device clusters.
  [Distributed-ML-with-MLX](https://github.com/DaveAldon/Distributed-ML-with-MLX),
  [exo MLX backend](https://deepwiki.com/exo-explore/exo/5.3-mlx-backend-and-model-loading).

Why this doesn't fit Mac+iPad+iPhone for us:

- **iOS isn't a supported distributed node.** The low-latency path (JACCL/
  RDMA over Thunderbolt) is Mac-only; the ring backend assumes an
  MPI-style host setup that iOS doesn't provide.
- **Layer-split inference needs every node online with a low-latency
  interconnect** for *every token*. Over Wi-Fi, with a phone that throttles
  on thermals and has far less RAM, this is slower and less reliable than
  running on the Mac alone.
- It optimizes the wrong axis for us: it lets a *cluster* run a model *too
  big for one device*. Our need is the opposite — let a *small device*
  borrow a *bigger device's* capacity.

### 4. The pragmatic path — local-network offload (reuses our seam)

Run an **OpenAI-compatible server on the Mac** and point the phone/tablet
at it:

- Server options on the Mac: `mlx_lm.server` (OpenAI-compatible chat
  completions), `mlx-omni-server` / `mlx-openai-server`, LM Studio, or our
  **own CLI** wrapped behind the same OpenAI shape.
  [Serving local LLMs with MLX](https://kconner.com/2025/02/17/running-local-llms-with-mlx.html),
  [mlx-omni-server](https://github.com/madroidmaq/mlx-omni-server).
- Client: our existing **`AICoScientistRemote` / `RemoteLanguageModel`**
  (M7 hosted-backing) already speaks OpenAI-compatible. Discover the Mac's
  endpoint via **Bonjour/`NetworkBrowser`** instead of a hardcoded URL.
- This is **offload/cooperation**, not layer-split distribution — but it is
  what the operator actually wants (an iPhone running a study by borrowing
  the Mac's Apple Silicon), it is **partially possible today** (the seam
  exists; only LAN discovery + a Mac server entry point are missing), and
  it keeps the architecture's DIP boundary intact.

## Constraints / caveats

- LAN-only (same network); not a true "anywhere via iCloud" path. (VPN-mesh
  products like LM Studio's LM Link show the remote-access variant but add a
  dependency.)
  [LM Studio + LM Link](https://www.digitalapplied.com/blog/lm-studio-locally-lm-link-iphone-local-llm-2026).
- The Mac must be awake with the server running.
- Local-first remains intact: offload is **additive** — the device still
  runs fully on-device when no server is found.
- Embeddings (MLX proximity, M5) would also need a remote route or stay
  on-device; scope in M19.

## Recommendation

1. **Do not pursue true distributed (layer-split) inference** across
   Mac+iPad+iPhone — not feasible/worthwhile on iOS today. Revisit only if
   Apple ships an iOS-capable distributed runtime.
2. **Pursue local-network offload as M19** — "LAN model offload": Bonjour/
   `NetworkBrowser` discovery of a Mac-hosted OpenAI-compatible endpoint,
   wired to `RemoteLanguageModel`, with a Mac "share this device for
   studies" server entry point. Reuses M7; small, high-value, local-first.

A follow-on draft `docs/MILESTONE-19-PLANNING-DRAFT.md` captures this.

## Sources

- [Private Cloud Compute — Apple Security Research](https://security.apple.com/blog/private-cloud-compute/)
- [Apple Intelligence, WWDC 2025 — Apple Newsroom](https://www.apple.com/newsroom/2025/06/apple-intelligence-gets-even-more-powerful-with-new-capabilities-across-apple-devices/)
- [Meet the Foundation Models framework — WWDC25 286](https://developer.apple.com/videos/play/wwdc2025/286/)
- [CloudKit — Apple Developer](https://developer.apple.com/icloud/cloudkit/)
- [Wi-Fi Aware — Apple Developer Documentation](https://developer.apple.com/documentation/WiFiAware)
- [Supercharge device connectivity with Wi-Fi Aware — WWDC25 228](https://developer.apple.com/videos/play/wwdc2025/228/)
- [Use structured concurrency with Network framework — WWDC25 250](https://developer.apple.com/videos/play/wwdc2025/250/)
- [MLX Distributed Communication — ml-explore](https://ml-explore.github.io/mlx/build/html/usage/distributed.html)
- [Distributed ML with MLX — DaveAldon](https://github.com/DaveAldon/Distributed-ML-with-MLX)
- [exo MLX backend — DeepWiki](https://deepwiki.com/exo-explore/exo/5.3-mlx-backend-and-model-loading)
- [Serving local LLMs with MLX — Kevin Conner](https://kconner.com/2025/02/17/running-local-llms-with-mlx.html)
- [mlx-omni-server — GitHub](https://github.com/madroidmaq/mlx-omni-server)
- [LM Studio + LM Link — Digital Applied](https://www.digitalapplied.com/blog/lm-studio-locally-lm-link-iphone-local-llm-2026)
