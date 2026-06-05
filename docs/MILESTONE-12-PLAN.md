# Milestone 12 Plan

Date: 2026-06-05

Working name:

```txt
Shared app core + iOS (iPhone) functional parity
```

## Status

Ready. Promoted from `docs/MILESTONE-12-PLANNING-DRAFT.md`.

## Goal

Bring the full demo experience to iPhone. Extract the cross-platform model
+ views into `Apps/Shared` consumed by both targets, then make the iOS app
a real demo (Studies, run, results + inspector, activity, Settings, graph,
charts, export) — local-first on-device, hosted backing optional.

## Design (resolved open questions)

- **Navigation:** `NavigationSplitView` (adaptive — stacks on iPhone,
  scales to iPad columns in M13).
- **Settings entry on iOS:** a gear in the Studies toolbar → a pushed
  in-app Settings screen (iOS has no `Settings` scene).
- **Grape on iOS:** confirm the iOS target builds Grape; if it fails to
  build for iOS 17, gate the Graph tab on iOS (charts + inspector still
  ship) and carry the graph to M13. (Halt-and-carry, not a blocker.)
- **Checkpoints:** Track A ships as its own PR (relocation; macOS green,
  iOS untouched), then Tracks B+C as a second PR (iOS sources the shared
  core + shims + surfaces).

## Primary Scope (Execution Order)

### Track A — Extract the shared app core (Apps/Shared) — PR 1

`git mv` the cross-platform model + views from `Apps/macOS` into
`Apps/Shared`: `Study`, `WorkflowRunner`, `SettingsStore`,
`HypothesisInspector`, `StudiesView`, `StudyDetailView`, `ChartsView`,
`GraphView`, `SettingsView`. macOS keeps `CoScientistDemoApp` (entry +
`Settings` scene). Point the `CoScientistDemo` target at
`Apps/Shared` + `Apps/macOS` in `project.yml`; the iOS target is
unchanged this PR. macOS builds byte-for-byte equivalent.

### Track B — Platform shims (#if os) — PR 2

Isolate macOS-only bits so the shared views compile on iOS: export via
`NSSavePanel` (macOS) vs the iOS share sheet (`UIActivityViewController`);
the `.radioGroup` picker style (macOS) vs `.segmented`/`.menu` (iOS); the
`Settings` scene (macOS) vs an in-app Settings screen (iOS).
`import AppKit` becomes macOS-only.

### Track C — iOS app shell + surfaces — PR 2

Point the iOS target (`CoScientistApp`) at `Apps/Shared` + `Apps/iOS`; add
the package products (Kit/MLX/Remote/FoundationModels) + Grape to it.
Replace the spike `ContentView` with the shared Studies experience via
`NavigationSplitView`, a toolbar-gear Settings screen, and a small default
on-device model. Confirm graph/charts/export render on the iOS simulator.

## Definition Of Done

- `Apps/Shared` holds the shared model + views; both targets build from it
  with only platform glue in `Apps/macOS` / `Apps/iOS`.
- macOS app still builds and behaves as before (no regression).
- iOS app builds on the iPhone simulator and runs the core flow: Studies →
  create/run (download + memory guard) → ranked hypotheses → inspector →
  live activity feed.
- Settings (providers/backends), charts, and export (share sheet) function
  on iOS. Graph functions on iOS, or is cleanly gated with the reason
  recorded (carried to M13).
- Export uses the iOS share sheet (no `NSSavePanel`/AppKit on iOS);
  `import AppKit` is macOS-only.
- New cross-platform logic (if any) is driven by a test written first
  (mock backend, no GPU); UI verified by building both apps.
- `swift build` clean; `swift test` green; macOS app builds; iOS app
  builds (simulator).
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M12 tracking + closeout docs land with the final commit.

## Non-Goals

- iPad-optimized layout + on-device memory/thermal hardening — that is M13.
- New features beyond macOS parity — this is a port.
- A separate SwiftPM UI library — shared source folders suffice.
