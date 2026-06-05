# Milestone 18 Closeout

Date: 2026-06-05

Milestone:

```txt
Distributed cross-device compute — feasibility spike
```

## Status

Complete.

## Delivered

- **`docs/SPIKE-distributed-compute.md`** — a cited feasibility study (13
  sources) answering whether CoScientist can harness Apple Silicon across
  the user's iCloud devices.
- **`docs/MILESTONE-19-PLANNING-DRAFT.md`** — the recommended follow-on
  ("LAN model offload") drafted from the spike's verdict.
- No production code changed (research milestone).

## Verdict (summary)

- **No first-party "share compute across iCloud devices" API exists** for
  third-party apps. The premise conflates Private Cloud Compute (Apple's
  servers), Foundation Models (on-device + PCC escalation), and
  iCloud/CloudKit (data sync) — none expose general cross-device compute.
- **True layer-split distributed inference** across Mac+iPad+iPhone is **not
  practical today**: MLX `mlx.distributed` (ring / JACCL-over-Thunderbolt)
  is Mac-and-interconnect oriented; iOS is not a viable distributed node;
  and it optimizes the wrong axis (cluster runs an over-large model) versus
  ours (a small device borrows a big device's capacity).
- **Feasible + recommended: local-network offload** — a Mac runs an
  OpenAI-compatible endpoint; the iPhone/iPad use it through our existing
  `RemoteLanguageModel` seam (M7), discovered via Bonjour/`NetworkBrowser`.
  Partially possible today; only LAN discovery + a Mac server entry point
  are missing. Drafted as **M19**.

## Validation

```txt
swift build           # unchanged, clean
swift test            # 152 tests / 36 suites green
git diff --check      # clean (docs-only)
```

## Retrospective

What worked:

- Time-boxed research produced a clear go/no-go and avoided committing build
  scope to a non-existent API.
- The spike connected the dots back to our own architecture: the M7
  hosted-backing seam already does 80% of the realistic path.

What to improve:

- The operator's premise ("Apple released compute sharing across iCloud
  devices") didn't map to a real public API — worth confirming premises
  with a quick survey before scoping, exactly as this spike did.

Carry forward:

- **M19 — LAN model offload** (drafted): Bonjour/`NetworkBrowser` discovery
  of a Mac-hosted OpenAI-compatible endpoint wired to `RemoteLanguageModel`,
  plus a Mac "share for studies" server entry point.
- Watch: Wi-Fi Aware for infra-free P2P discovery (iOS 26); an iOS-capable
  MLX distributed runtime would reopen the true-distributed option.
- Operator-pending from M17: live two-device iCloud sync verification.
