# Milestone 15 Planning Draft

Date: 2026-06-05

Working name:

```txt
iOS — redesigned UX + iPad layout + on-device hardening
```

## Status

Ready. Promoted from `docs/MILESTONE-15-PLANNING-DRAFT.md`.

Resolved: critical thermal → stop-with-partial-results (reuses the cancel
path); the memory-fit check reuses the catalog model's `minRAMGB`.

## Goal

Bring the M13/M14 control-flow redesign to iOS and make it native on iPad
and robust on-device. Because the redesigned views live in `Apps/Shared`,
the new model selection, install-aware pickers, run config, and results
outcome already compile for iOS; M15 makes them feel right on iPhone/iPad
(adaptive layout, the model picker's download/share affordances, the
Settings screen) and hardens the on-device run path against memory/thermal
limits. (Absorbs the earlier iPad-polish + hardening scope.)

## Context

Operator: "improve this, first on mac then iOS." After M13 (model selection)
+ M14 (run config + results) land in `Apps/Shared`, iOS inherits them — but
iOS needs adaptive layout (iPad multi-column, inspector as a side pane), the
new picker's download UI verified on iOS, an in-app Settings screen for the
slimmed providers/downloads, and on-device hardening (the GPU cache cap is
currently set nowhere in the real apps; memory/thermal pressure should warn/
stop cleanly, not crash). Apply `swiftui-design-principles`, `swiftui-pro`,
`swiftui-view-refactor`, `writing-for-interfaces`.

## Usage Scenarios

### Scenario 1: The redesigned flow on iPhone + iPad

Expected behavior:

- iPhone: the M13/M14 model selection, install-aware picker, Advanced config,
  and results-outcome flow work in a compact, stacked layout.
- iPad / regular width: Studies + detail + inspector render as columns; the
  hypothesis inspector is a trailing pane, not a full-screen push.

### Scenario 2: Graceful on-device

Expected behavior:

- A GPU memory cap is applied on iOS; a low-memory pre-run check warns/blocks
  instead of starting a doomed run; critical thermal state stops the run
  cleanly with a recorded reason (no crash).

## Primary Scope

### Track A — On-device hardening (Kit pure logic + MLX/app wiring)

A pure decision (free memory + model RAM need → warn/block/proceed; thermal
state → continue/stop), unit-tested with fed-in signals; the iOS app reads
the live signals and feeds them in, applies the GPU cache cap
(`MLXRuntime.setGPUCacheLimit`), and routes a critical-thermal stop through
the existing cancel path. (Reuses `minRAMGB`/`approxSizeGB`.)

### Track B — iPad-adaptive layout (Apps/Shared)

Size-class-aware layout so Studies + detail + inspector are columns on
iPad/regular and stack on iPhone/compact; inspector as a trailing pane where
space allows. macOS layout stays correct.

### Track C — iOS surface polish (Apps/iOS + Apps/Shared)

Verify/adjust the M13 install-aware picker's download affordance and the M14
results outcome on iOS; the in-app Settings screen reflects the slimmed
providers/downloads; share-sheet export already in place. Build for the iOS
simulator across compact + regular.

## Definition Of Done

- The memory-guard + thermal-action decisions are pure and unit-tested with
  fed-in signals; the iOS app applies a GPU cache cap and stops cleanly on
  critical thermal (no crash) with a recorded reason.
- A low-memory pre-run check warns/blocks instead of starting a doomed run.
- iPad/regular renders Studies + detail + inspector as columns (inspector a
  trailing pane); iPhone/compact stacks — verified building the iOS app for
  both idioms.
- The M13/M14 flow (model selection, picker, Advanced config, results
  outcome) works on iOS; no regression to the iPhone flow or the macOS app.
- New decision logic is test-first (mock, no GPU); UI verified by building
  both apps.
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M15 tracking + closeout docs land with the final commit.

## Non-Goals

- New analysis features — port + adapt + harden only.
- Background execution; per-platform visual redesign beyond adaptive layout.
- iOS study import (document picker) + iOS HF-cache-path accuracy — separate
  follow-ups unless trivially included.

## Open Questions

- **Thermal stop policy.** Stop-with-partial vs. pause/resume on critical.
  Lean stop-with-partial (reuses cancel path).
- **Memory threshold margin.** Lean reuse `minRAMGB`/`approxSizeGB` for the
  check.

## Risk

- **Device-specific signals.** Factor memory/thermal into pure, mock-tested
  logic; feed live signals in. **Adaptive layout regressions on macOS** —
  verify both app builds + the macOS layout.

## Scope Class

Medium. Pure hardening logic + adaptive layout on shared views + iOS surface
verification of the M13/M14 redesign.

Estimated 3–4 (Track A) + 3–4 (Track B) + 2–3 (Track C), ~8–11 commits.
