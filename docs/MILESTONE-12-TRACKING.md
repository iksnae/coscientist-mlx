# Milestone 12 Tracking

Date: 2026-06-05

Milestone:

```txt
Shared app core + iOS (iPhone) functional parity
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | TBD |
| Elapsed | TBD |
| Scope class | Large |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| `Apps/Shared` holds the shared model + views; both targets build from it. | Pending | Track A/C |
| macOS app still builds and behaves as before (no regression). | Pending | Track A |
| iOS app builds on the simulator and runs the core flow (Studies → run → results → inspector → activity). | Pending | Track C |
| Settings, charts, export (share sheet) function on iOS; graph functions or is cleanly gated. | Pending | Track B/C |
| Export uses the iOS share sheet; `import AppKit` is macOS-only. | Pending | Track B |
| New cross-platform logic is test-first (mock, no GPU); UI verified by building both apps. | Pending | all tracks |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Pending | `git grep` check |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Pending | — |
| `swift test` | Pending | — |
| macOS app build | Pending | — |
| iOS app build (simulator) | Pending | — |
| `git diff --check` | Pending | — |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| `NavigationSplitView` for iOS. | Accepted | Adaptive; stacks on iPhone, scales to iPad in M13. |
| Settings via toolbar gear → in-app screen on iOS. | Accepted | iOS has no `Settings` scene. |
| Two-PR checkpoints (A; then B+C). | Accepted | Isolate the big relocation refactor (macOS green) before iOS surfaces. |
| Grape-on-iOS: gate + carry to M13 if it won't build. | Accepted | Don't block the milestone on one dependency's iOS support. |
