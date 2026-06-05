# Milestone 12 Closeout

Date: 2026-06-05

Milestone:

```txt
Shared app core + iOS (iPhone) functional parity
```

## Status

Complete.

## Delivered

### Track A — Shared app core (Apps/Shared) — PR #42

Relocated the cross-platform model + views (`Study`, `WorkflowRunner`,
`SettingsStore`, `HypothesisInspector`, `StudiesView`, `StudyDetailView`,
`ChartsView`, `GraphView`, `SettingsView`) from `Apps/macOS` into
`Apps/Shared`. macOS sources `Apps/Shared` + `Apps/macOS` (which keeps
only `CoScientistDemoApp`); macOS built unchanged.

### Track B — Platform shims (#if os) — PR #43

- `PlatformExport` (`Apps/Shared/PlatformExport.swift`): macOS `NSSavePanel`
  vs iOS `UIActivityViewController` share sheet. Shared views dropped
  `import AppKit`.
- `StudiesView`: study import gated to macOS (`NSOpenPanel`); export via
  `PlatformExport`; iOS gets a Settings gear → sheet.
- `SettingsView`: `.radioGroup` picker style + the fixed window frame
  gated to macOS.
- `AICoScientistKit`: `PlatformPaths.userBase` (home on macOS, app
  documents on iOS) replaces `homeDirectoryForCurrentUser` in
  `DownloadGuard` + `ModelCache`, so Kit compiles for iOS.

### Track C — iOS app shell + surfaces — PR #43

`CoScientistApp` (iOS) now hosts the shared `StudiesView` with a SwiftData
container (`NavigationSplitView`). `project.yml` iOS target sources
`Apps/Shared` and links Kit/MLX/Remote/FoundationModels + Grape. The full
surface set builds on iOS: Studies, run (download + memory guard), ranked
results + inspector, activity feed, Settings, charts, graph, export.

## Validation

```txt
swift build                                   # clean on Apple Silicon
swift test                                    # 138 tests / 32 suites green (+1)
xcodebuild … -scheme CoScientistDemo          # macOS app BUILD SUCCEEDED
xcodebuild … -scheme CoScientistApp \
  -destination 'generic/platform=iOS Simulator'   # iOS app BUILD SUCCEEDED
git grep "import MLX" -- '*.swift'            # only AICoScientistMLX (+ Package.swift comment)
git diff --check                              # whitespace clean
```

The iOS app is verified by a clean simulator build (incl. Grape + MLX +
Foundation Models). A real on-device run (downloading a model on iPhone)
is a manual/opt-in step, not part of `swift test`.

## Retrospective

What worked:

- The two-PR checkpoint paid off: PR #42 was a pure relocation (macOS
  green, trivially bisectable) before any iOS behavior changed.
- Most macOS views were already cross-platform SwiftUI (`StudiesView`
  already used `NavigationSplitView`), so the iOS port was mostly
  `#if os` shims for AppKit + a thin app shell — not a rewrite.
- **Grape compiled for iOS** — the milestone's main unknown — so the
  graph ships on iOS with no gating.
- The iOS build surfaced a real cross-platform bug in Kit
  (`homeDirectoryForCurrentUser`); fixing it via `PlatformPaths` keeps the
  domain layer honest on both platforms.

What to improve:

- The HF cache path on iOS (`PlatformPaths.userBase/.cache/...`) is a
  reasonable default but may not match exactly where the MLX/Hub loader
  downloads on iOS, so `ModelCache` introspection (isDownloaded/sizes)
  could be off on iOS — refine in M13.
- Study **import** is macOS-only (NSOpenPanel); iOS import via a document
  picker is deferred.
- Verified by build, not by a launched on-device run; no UI test target.

Carry forward (M13):

- iPad-adaptive multi-column layout + inspector-as-side-pane.
- On-device memory/thermal hardening for runs on iPhone.
- iOS HF cache-path accuracy; iOS study import (document picker).
