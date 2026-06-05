# Milestone 12 Planning Draft

Date: 2026-06-05

Working name:

```txt
Shared app core + iOS (iPhone) functional parity
```

## Status

Draft. Not yet promoted to MILESTONE-12-PLAN.md.

## Goal

Bring the full demo experience to iPhone. Today `Apps/iOS` is a single-
screen validation spike; the real demo (Studies library, run, ranked
results + inspector, activity feed, graph, charts, Settings, export) lives
only in `Apps/macOS`. M12 extracts the cross-platform model + views into
`Apps/Shared` consumed by both targets, then makes the iOS app a real
demo with the same surfaces on iPhone — local-first on-device, with hosted
backing optional. When a developer launches the iOS app, they get the
Studies experience, not a probe.

## Context

Operator intention (2026-06-05): "make our demo app work on iOS." Roadmap
carry-forward theme "iOS parity" (from M8–M10, which were macOS-first).
Most of the macOS UI is cross-platform SwiftUI; the model layer
(`Study` SwiftData model, `WorkflowRunner`, `SettingsStore`) and the
results views (`HypothesisInspector`, `ChartsView`, `GraphView`) have no
AppKit dependency. The macOS-only bits are localized: `NSSavePanel`
export (`StudyDetailView`), the `.radioGroup` picker style and the
`Settings` scene (`SettingsView` / `CoScientistDemoApp`).

## Usage Scenarios

### Scenario 1: Run a study on iPhone

Expected behavior:

- Launch → a Studies list; create a study, set a goal, run it (with the
  existing download-size guard + GPU memory cap for on-device models).
- See ranked hypotheses, tap one for the inspector, watch the activity
  feed update live.

### Scenario 2: Same code, both platforms

Expected behavior:

- The Studies/run/results/inspector/activity/graph/charts/Settings views
  live once in `Apps/Shared`; macOS and iOS targets compile the same
  sources plus thin platform glue (export, picker style, settings host).
- `swift test` is unaffected (app code isn't in the package test path).

## Primary Scope

### Track A — Extract the shared app core (Apps/Shared)

Move the cross-platform model + views from `Apps/macOS` into `Apps/Shared`:
`Study`, `WorkflowRunner`, `SettingsStore`, `HypothesisInspector`,
`StudiesView`, `StudyDetailView`, `ChartsView`, `GraphView`, `SettingsView`.
Point both `CoScientistDemo` (macOS) and `CoScientistApp` (iOS) at
`Apps/Shared` + their platform folder in `project.yml`; add the package
products (Kit/MLX/Remote/FoundationModels) and Grape to the iOS target.
macOS must build byte-for-byte equivalent after the move.

### Track B — Platform shims (#if os)

Isolate the macOS-only bits behind platform conditionals so the shared
views compile on iOS: run export via `NSSavePanel` (macOS) vs the iOS
share sheet (`UIActivityViewController`); the `.radioGroup` picker style
(macOS) vs an iOS-appropriate style; the `Settings` scene (macOS window)
vs an in-app Settings screen reached from the iOS UI.

### Track C — iOS app shell + surfaces

Replace the iOS spike `ContentView` with the shared Studies experience
(keep the probe available behind a debug affordance if useful). Wire
navigation for iPhone (NavigationStack/Split), an in-app Settings screen,
and confirm graph (Grape), charts, and export all render on iOS. Default
the on-device generator to a small model (e.g. `qwen3-1.7b`) for memory.

## Definition Of Done

- `Apps/Shared` holds the shared model + views; both targets build from it
  with only platform glue in `Apps/macOS` / `Apps/iOS`.
- macOS app still builds and behaves as before the extraction (no
  regression).
- iOS app builds and runs the core flow on an iPhone simulator: Studies →
  create/run a study (download guard + memory cap) → ranked hypotheses →
  inspector → live activity feed.
- Settings (providers/backends), graph, charts, and export (share sheet)
  all function on iOS.
- Export uses the iOS share sheet (no `NSSavePanel`/AppKit on iOS);
  `import AppKit` is macOS-only.
- New cross-platform logic (if any) is driven by a test written first
  (mock backend, no GPU); UI is verified by building both apps.
- `swift build` clean; `swift test` green; macOS app builds; iOS app
  builds (simulator).
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M12 tracking + closeout docs land with the final commit.

## Non-Goals

- iPad-optimized layout + on-device memory/thermal hardening — that is M13.
- New features beyond what macOS already has — this is a port, not new
  capability.
- A separate SwiftPM UI library — `Apps/Shared` source folders shared by
  both xcodegen targets is enough.
- Retiring the per-item validation spike's telemetry value — keep it
  reachable if cheap.

## Open Questions

- **iOS navigation shape.** `NavigationStack` (iPhone) vs
  `NavigationSplitView` (adaptive). Lean `NavigationSplitView` so the same
  structure scales to iPad in M13. Delivery detail.
- **Settings entry point on iOS.** A toolbar gear → pushed/sheet Settings
  screen. Lean a gear in the Studies toolbar. Delivery detail.
- **Grape on iOS 17.** Expected to support iOS; confirm at delivery and
  gate the Graph tab if a specific iOS version is required.

## Risk

- **Large refactor touching both apps.** Move files first with macOS
  building green before adding iOS surfaces; commit per moved area so
  regressions bisect cleanly.
- **Grape iOS support / dependency wiring.** If Grape doesn't build for
  the iOS target, gate the Graph tab on iOS (charts + inspector still
  ship) and carry the graph to M13.
- **On-device memory on iPhone.** Default to a small model + the existing
  download guard + GPU cache cap; surface a clear message on low memory.

## Scope Class

Large. A shared-extraction refactor plus iOS wiring for every surface in
one milestone (per the operator's "all surfaces in the functional iOS
app"). Kept grindable by ordering: extract (macOS green) → shims → iOS
surfaces, each commit-able.

Estimated 6–8 commits (Track A) + 3–4 (Track B) + 4–6 (Track C),
~13–18 commits.
