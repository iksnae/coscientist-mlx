# Milestone 13 Planning Draft

Date: 2026-06-05

Working name:

```txt
iOS polish — iPad layout + on-device hardening
```

## Status

Draft. Not yet promoted to MILESTONE-13-PLAN.md.

## Goal

Make the iOS app feel native on iPad and robust under on-device limits.
M12 brings functional parity to iPhone via the shared core; M13 adapts the
layout for iPad's larger canvas (multi-column navigation, the inspector as
a side pane rather than a push) and hardens the on-device run path against
memory/thermal pressure so a study doesn't crash a phone.

## Context

Carry-forward from M12 (shared core + iPhone parity). The shared views in
`Apps/Shared` already adapt via SwiftUI, but iPhone-first navigation and
the inspector-as-push don't use iPad space well, and on-device generation
needs graceful behavior when memory/thermals spike (the iOS spike already
reads `os_proc_available_memory()` and `thermalState`).

## Usage Scenarios

### Scenario 1: iPad multi-column

Expected behavior:

- On iPad, Studies + detail + inspector use a multi-column layout; the
  hypothesis inspector is a trailing pane (as on macOS), not a full-screen
  push.

### Scenario 2: Graceful under pressure

Expected behavior:

- If free memory is low before a run, the app warns and suggests a smaller
  model rather than starting and crashing.
- On serious/critical thermal state mid-run, the run pauses/stops cleanly
  with a recorded reason (not a crash).

## Primary Scope

### Track A — iPad-adaptive layout (Apps/Shared)

Use `NavigationSplitView` columns and size-class-aware layout so the
Studies list, detail, and inspector lay out as panes on iPad / regular
width, and stack on iPhone / compact width. The inspector becomes a
trailing pane where space allows.

### Track B — On-device hardening (Apps/Shared + AICoScientistMLX as needed)

A pre-run memory check (warn/block when free memory is below the model's
estimated need, reusing `DownloadGuard`-style logic), and thermal-aware
behavior (surface thermal state; stop the run cleanly on critical). Keep
the GPU cache cap; expose a clear status, never crash.

## Definition Of Done

- On iPad / regular size class, Studies + detail + inspector render as a
  multi-column layout; on iPhone / compact they stack (verified building
  the iOS app for both idioms).
- A low-memory pre-run check warns/blocks with a clear message instead of
  starting a doomed run (pure decision logic unit-tested).
- Critical thermal state during a run stops it cleanly with a recorded
  reason; no crash (decision logic unit-tested with a mock signal).
- No regression to the iPhone flow or the macOS app.
- New decision logic is driven by a test written first (mock, no GPU).
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M13 tracking + closeout docs land with the final commit.

## Non-Goals

- New analysis features — polish + robustness only.
- Background execution / run-while-backgrounded — out of scope.
- Per-platform visual redesign beyond adaptive layout.

## Open Questions

- **Thermal stop policy.** Pause-and-resume vs. stop-with-partial-results
  on critical thermal. Lean stop-with-partial (simpler, matches the
  existing cancel path). Delivery detail.
- **Memory threshold.** What free-memory margin to require per model size.
  Lean reuse the model's `minRAMGB`/`approxSizeGB` metadata for the check.

## Risk

- **Thermal/memory testing is device-specific.** Factor the decisions into
  pure, mock-tested logic (free-memory + thermal-state → action); the real
  signals are read on-device and fed in.
- **Adaptive layout regressions on macOS.** The shared views must stay
  correct on macOS; verify both app builds and the macOS layout after
  changes.

## Scope Class

Small-to-Medium. Adaptive layout on the shared views + a pure
hardening-decision component with thin platform signal wiring.

Estimated 3–4 commits (Track A) + 3–4 (Track B), ~6–8 commits.
