# Milestone 19 Planning Draft

Date: 2026-06-05

Working name:

```txt
LAN model offload — borrow a Mac's Apple Silicon over the local network
```

## Status

Draft. Not yet promoted to MILESTONE-19-PLAN.md.

## Goal

Let an iPhone/iPad run a study by **offloading model inference to a Mac on
the same network** — discovering the Mac's OpenAI-compatible endpoint via
Bonjour/`NetworkBrowser` and routing roles to it through the existing
`RemoteLanguageModel` seam. The realistic interpretation of "harness Apple
Silicon across my devices," per the M18 spike
(`docs/SPIKE-distributed-compute.md`).

## Context

M18 concluded there is **no first-party cross-device compute API** and that
**layer-split distributed inference is impractical on iOS**, but that
**local-network offload is feasible and mostly already wired**: M7 gave us
`AICoScientistRemote` / `RemoteLanguageModel` (OpenAI-compatible) and
per-role routing (`StudyRouting`, M13). What's missing is (a) a Mac-side
"share this device" server entry point and (b) LAN discovery so the phone
finds it without a hardcoded URL.

## Usage Scenarios

### Scenario 1: Discover and offload

- On the iPhone, a study's Generator/Reviewer can pick a discovered
  "<Mac name> (on your network)" endpoint; the run executes on the Mac and
  results stream/persist on the phone as today. With no Mac found, the
  picker simply doesn't offer it (local-first unchanged).

### Scenario 2: Share a Mac for studies

- On the Mac, a toggle ("Share this Mac for studies on my network") starts
  a local OpenAI-compatible endpoint backed by the on-device MLX models and
  advertises it via Bonjour.

## Primary Scope (candidate)

### Track A — Mac server entry point

A local OpenAI-compatible endpoint on the Mac backed by the MLX adapter
(or a documented `mlx_lm.server` bridge), advertised via Bonjour
(`NWListener` + service type). Pure request/route logic in the Kit where
possible; MLX stays quarantined.

### Track B — LAN discovery + client wiring

`NetworkBrowser`/Bonjour discovery surfaced as selectable endpoints in the
model picker; selecting one routes via `RemoteLanguageModel`. Pure
discovery-result → `ModelChoice` mapping unit-tested with fed-in results.

### Track C — Embeddings + guards

Decide embeddings (remote route vs stay on-device); reuse `RunGuard`
expectations (the phone's role becomes orchestration, not heavy compute).

## Open Questions

- **[?]** Server entry point: native `NWListener` endpoint vs. document a
  `mlx_lm.server` bridge for v1.
- **[?]** Auth on the LAN endpoint (token? pairing via DeviceDiscoveryUI?)
  vs. trust-the-LAN for v1.
- **[?]** Discovery transport: Bonjour now; Wi-Fi Aware later for infra-free
  P2P.

## Non-Goals

- True layer-split distributed inference (M18: not pursued).
- Remote-over-internet / VPN mesh access (LAN-only for v1).

## Scope Class

Medium. New networking surface, but the inference seam + routing already
exist.
