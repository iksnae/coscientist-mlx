# Milestone 15 Closeout

Date: 2026-06-05

Milestone:

```txt
iOS — redesigned UX + iPad layout + on-device hardening
```

## Status

Complete.

## Delivered

### Track A — On-device hardening (AICoScientistKit + Apps/Shared)

- `RunGuard` (`Sources/AICoScientistKit/Engine/RunGuard.swift`): pure
  `memory(freeMB:modelApproxGB:)` → proceed/warn/block and `thermal(_:)` →
  proceed/stop on critical, with `DeviceThermalState`. Unit-tested.
- `WorkflowRunner` (iOS): caps the GPU buffer cache
  (`MLXRuntime.setGPUCacheLimit`), **blocks a doomed run** when free memory
  is below the model's footprint (clear message, study marked failed), and
  **stops cleanly on critical thermal** mid-run (routes through the cancel
  path). Device signals (`os_proc_available_memory()`,
  `ProcessInfo.thermalState`) are read in the app and fed to `RunGuard`.

### Track B — iPad-adaptive inspector (Apps/Shared)

- `StudyDetailView.inspectorSplit` is size-class adaptive: a trailing
  inspector pane on regular width (iPad / macOS), a sheet on compact width
  (iPhone) so the results stay full-width.

### Track C — iOS surface verification

- The full M13/M14 redesign (per-study Generator/Reviewer model selection,
  install/system-aware picker, Advanced run config, results-outcome header,
  Issues banner) is in `Apps/Shared`, so iOS inherits it; verified by a
  clean iOS simulator build across the redesigned surfaces.

## Validation

```txt
swift build                                   # clean on Apple Silicon
swift test                                    # 148 tests / 35 suites green (+2)
xcodebuild … -scheme CoScientistDemo          # macOS app BUILD SUCCEEDED
xcodebuild … -scheme CoScientistApp …iOS Sim  # iOS app BUILD SUCCEEDED
git grep "import MLX" -- '*.swift'            # only AICoScientistMLX (+ Package.swift comment)
git diff --check                              # whitespace clean
```

Real on-device behavior (a model downloading/running on a physical iPhone,
and live thermal/memory pressure) is a manual/opt-in step; the decision
logic is unit-tested and the signal wiring is gated to iOS.

## Retrospective

What worked:

- Shared views meant the whole M13/M14 redesign came to iOS for free; M15
  was hardening + adaptive layout, not a re-port.
- `RunGuard` as pure logic kept the device-specific safety decisions
  unit-testable; the app just feeds live signals.
- The adaptive inspector (pane vs sheet by size class) reuses one
  `HypothesisInspector` across iPhone/iPad/macOS.

What to improve:

- Thermal stop reuses the cancel path, so the recorded reason reads
  "cancel" rather than "thermal" — a clearer reason string would help.
- iPad multi-column for the *Studies list + detail* relies on the existing
  `NavigationSplitView`; deeper iPad layout tuning could go further.
- Verified by build, not a launched device run.

Carry forward:

- **Multi-indicator run progress** (operator idea, 2026-06-05): replace the
  single overloaded progress bar with stacked indicators (segmented /
  radial / standard / charts / custom SwiftUI) conveying activity + phase
  progress. Candidate theme.
- **Model registry sync** (operator idea): updatable model index hosted on
  the repo / GitHub Pages.
- Standing: `StudyDocument` round-trips generator/reviewer + run config;
  Apple Foundation Models in the picker; thermal reason string; prune
  unused `SettingsStore` fields.
