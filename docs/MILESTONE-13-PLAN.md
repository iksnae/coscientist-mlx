# Milestone 13 Plan

Date: 2026-06-05

Working name:

```txt
iOS polish — iPad layout + on-device hardening
```

## Status

Ready. Promoted from `docs/MILESTONE-13-PLANNING-DRAFT.md`.

## Goal

Make the iOS app feel native on iPad and robust under on-device limits.
M12 brought functional parity to iPhone via the shared core; M13 adapts
the layout for iPad (multi-column navigation, inspector as a side pane
rather than a push) and hardens the on-device run path against
memory/thermal pressure so a study doesn't crash a phone.

## Design (resolved open questions)

- **Thermal policy:** stop-with-partial-results on critical thermal state
  (reuses the existing cancel path; simpler than pause/resume).
- **Memory threshold:** reuse the catalog model's `minRAMGB` /
  `approxSizeGB` for the pre-run free-memory check (consistent with the
  `DownloadGuard` disk check).
- **Layout:** size-class-aware shared views — the inspector becomes a
  trailing pane in regular width (iPad/macOS), a push/sheet in compact
  width (iPhone).

## Primary Scope (Execution Order)

### Track A — On-device hardening (AICoScientistKit, pure + tested)

A pure `RunGuard`-style decision: given free memory + a model's RAM need →
warn/block/proceed; and a thermal action (nominal/fair/serious/critical →
continue/stop). Unit-tested with fed-in signals (no device). The app reads
the live signals (`os_proc_available_memory()`, `ProcessInfo.thermalState`)
and feeds them in; a critical-thermal stop routes through the existing
run-cancel path with a recorded reason.

### Track B — iPad-adaptive layout (Apps/Shared)

Size-class-aware layout so Studies + detail + inspector render as columns
on iPad / regular width and stack on iPhone / compact width; the
hypothesis inspector becomes a trailing pane where space allows. The
shared views must stay correct on macOS.

## Definition Of Done

- The memory-guard decision (free memory + model need → warn/block/proceed)
  and the thermal action (state → continue/stop) are pure and unit-tested
  with fed-in signals.
- The iOS app applies the pre-run memory check (clear warning instead of a
  doomed run) and stops cleanly with a recorded reason on critical thermal
  (no crash).
- On iPad / regular size class the inspector renders as a trailing pane;
  on iPhone / compact it stacks — verified building the iOS app.
- No regression to the iPhone flow or the macOS app (both build; macOS
  layout unchanged).
- New decision logic is driven by a test written first (mock, no GPU).
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M13 tracking + closeout docs land with the final commit.

## Non-Goals

- New analysis features — polish + robustness only.
- Background / backgrounded-run execution.
- iOS study import (document picker) and iOS HF-cache-path accuracy —
  carried from M12 as separate follow-ups unless trivially included.
- Per-platform visual redesign beyond adaptive layout.
