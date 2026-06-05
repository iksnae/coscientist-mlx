---
name: app-logs
description: Collect logs and troubleshoot the CoScientist macOS/iOS apps when a run fails, the app crashes, behaves oddly, or a study errors immediately. Covers pulling logs from the macOS app, the iOS Simulator, and a real iPhone/iPad (incl. the sudo requirement for device log collection), finding crash reports, and a failure-mode → cause table for the issues already seen (model run fails on device, simulator can't run MLX, always-downloading, off-screen macOS window, background-Metal crash). Use when asked to "check logs", "check sys logs", diagnose a crash/failure, or figure out why a run/build/app misbehaves. For Xcode Cloud build failures use the xcode-cloud skill instead.
---

# app-logs

How to get logs out of the CoScientist apps and turn them into a diagnosis.
The fastest signal is often **not** the logs — the apps surface failures in
the UI — so check that first, then escalate to logs. Helper:
[`collect-logs.sh`](collect-logs.sh).

## Fastest signal first: the in-app error

`WorkflowRunner` catches run failures and sets `status = "Error: …"` (or a
specific guard message). Before pulling logs, ask the operator what the
**status line under "Run study"** shows — it usually names the exact
failure (model load error, memory block, etc.).

## Where logs live

| Target | How | sudo? |
| --- | --- | --- |
| **macOS app** | `collect-logs.sh mac [min]` → `log show --predicate 'process CONTAINS "CoScientist"'` | no |
| **iOS Simulator** | `collect-logs.sh sim [min]` → `xcrun simctl spawn booted log show …` | no |
| **Real iPhone/iPad** | `collect-logs.sh device <udid>` prints the command; run `sudo log collect --device-udid <udid> --last 15m --output /tmp/dev.logarchive`, then `collect-logs.sh show /tmp/dev.logarchive` | **yes** (collect only) |
| **Crash reports** | `collect-logs.sh crashes` — macOS `~/Library/Logs/DiagnosticReports/*.ips`; device synced to `~/Library/Logs/CrashReporter/MobileDevice/<device>/` | no |
| **Devices/sims** | `collect-logs.sh devices` (`xcrun devicectl list devices`, `xcrun simctl list devices booted`) | no |

Notes:
- **Device `log collect` requires root.** The agent must not run `sudo`
  unprompted — hand the operator the exact command (e.g. via `!` in the
  session), then read the resulting `.logarchive` (reading needs no sudo).
- Reading a `.logarchive` with `log show <archive>` works on any Mac, no
  device or sudo needed.
- macOS window/state oddities often live in **UserDefaults**, not logs:
  `defaults read <bundle-id>` (bundle ids `com.iksnae.coscientist.{demo,app}`).

## Failure-mode → cause (seen in this project)

| Symptom | Likely cause | Fix / check |
| --- | --- | --- |
| Study **fails immediately on a real device** | The run loads the **generator + the embedder** (`qwen3-embed-0.6b`, always on-device). If the embedder isn't cached and you're offline, it can't fetch → instant error. | Settings ▸ Models: confirm the **embedder** shows ✓; download it (or run once online). |
| Study run **fails on the iOS Simulator** | **MLX needs Metal features the Simulator lacks** — on-device model runs don't work there. | Test on a **physical** device (`docs/IOS.md`). |
| iPad **always shows "download"** even for cached models | HF cache path mismatch (the downloader's iOS sandbox path ≠ `ModelCache`'s). | Fixed: `SettingsStore` sets `HF_HUB_CACHE` to `ModelCache.huggingFaceCacheURL.path`. Verify it's set. |
| App **crashes when backgrounded mid-run** | iOS forbids creating a Metal compute context in the background → `IOGPUMetalError: Insufficient Permission`. | Keep foreground during a run; mid-run thermal/background handling in `WorkflowRunner`. |
| Run **blocked with a memory message** on a low-RAM device | `RunGuard.memory` blocked a doomed run. | Pick a smaller model; check free vs model footprint. |
| macOS window **huge / off-screen** | Stale `NSWindow Frame …` in UserDefaults (content has flexible height, so it can't force this — it's a saved frame). | `defaults delete <bundle-id> "NSWindow Frame …"`, then quit+relaunch. |
| Build / Xcode Cloud failure | Not an app-log issue. | Use the **xcode-cloud** skill. |

## Method

1. Ask for / read the in-app `Error: …` status.
2. `collect-logs.sh devices` to see what's connected/booted.
3. Pull the matching target's logs; grep for `error|fail|metal|gpu|decode|cache`.
4. Cross-reference the table above; if it's build/CI, switch to `xcode-cloud`.
5. No crash report + graceful `Error:` = a thrown Swift error (most model/
   cache/network issues). A `.ips` = a real crash (often Metal/background).
