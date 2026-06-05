# Milestone 21 Closeout

Date: 2026-06-05

Milestone:

```txt
Professional UI redesign — main study view, sidebar, pickers, results
```

## Status

Complete.

## Delivered

Addresses every issue in the operator's screenshot (identical sidebar
titles, pickers hiding the choice + duplicated captions, the conclusion
repeating the top hypothesis verbatim, dev-log status, flat hierarchy).

### Track A — IA + hierarchy + view split

- Extracted `ActivityFeedView` (`Apps/Shared/ActivityFeedView.swift`) out of
  `StudyDetailView` (sparkline header + auto-following event log), shrinking
  the detail view and keeping each view focused (`swiftui-view-refactor`).
- Tidied the outcome/config spacing toward a consistent rhythm.

### Track B — Sidebar + pickers

- `Study.titleIsCustom`: the title **auto-tracks the goal's first line until
  the user renames it**; new studies seed an **empty** goal — so the sidebar
  shows real goals instead of a row of identical "New research goal" seeds.
  `StudyRow` shows the title (or "Untitled study").
- `ModelChoicePicker`: the control now shows the **selected model** inline
  (title + model name + chevron); the caption is one concise line about the
  *current* choice (on-device fit/install, or hosted), and the full strengths
  blurb moved into the **menu items** — so two pickers no longer render the
  same long paragraph twice.

### Track C — Results + status copy

- The Conclusion block leads with the meta-review **synthesis**; the top
  hypothesis is shown **truncated with a Show more / Show less** toggle and a
  "TOP HYPOTHESIS" label — no longer a verbatim copy of the first ranked row.
- `RunStatusText` (`Sources/AICoScientistKit/Engine/RunStatusText.swift`): a
  pure, unit-tested formatter for plain-language, correctly pluralized status
  ("Done · 3 hypotheses · 1 repair · 1 decode failure" — fixes "1 repairs").
  Used by `StudyDetailView.statusLine`, `WorkflowRunner`, and the issues banner.

## Validation

```txt
swift build                       # clean
swift test                        # 159 tests / 38 suites green (+2)
xcodebuild … CoScientistDemo      # macOS BUILD SUCCEEDED
xcodebuild … CoScientistApp …iOS  # iOS BUILD SUCCEEDED
git grep "import MLX" -- '*.swift' # only the Package.swift comment
git diff --check                  # clean
```

Visual outcome is verified by building both platforms; the shared views keep
the M15 size-class-adaptive inspector working on iPhone/iPad/macOS. A live
visual pass on device is the operator's to confirm.

## Retrospective

What worked:

- The title-auto-tracks-goal pattern (with a `titleIsCustom` flag) fixes the
  identical-sidebar problem without forcing users to name studies.
- Pulling status text into a pure Kit formatter made the pluralization fix
  testable and reusable across the runner + detail view + banner.
- Synthesis-led conclusion + truncation removes the most jarring duplication
  while keeping the full text one tap away.

What to improve:

- `titleIsCustom` is not carried in `StudyDocument`/`StudyConfig`; an imported
  study's title won't auto-track after import (the title value is preserved).
  A later pass could thread it through the round-trip.
- The config zone still stays fully expanded after a run; a collapse-to-summary
  interaction was deferred (scope) and remains a polish candidate.
- Verified by build, not a launched-device visual review.

Carry forward:

- Config-collapse-after-run polish; carry `titleIsCustom` through the document
  round-trip; drop the unused `study.generatorKey` field in a schema pass.
- **M19 — LAN model offload** is the next drafted milestone.
- Candidate themes: multi-indicator run progress; model registry sync;
  parity-test harness; native FM tool calling.
