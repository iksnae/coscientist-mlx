# Milestone 21 Planning Draft

Date: 2026-06-05

Working name:

```txt
Professional UI redesign — main study view, sidebar, pickers, results
```

## Status

Draft. Not yet promoted to MILESTONE-21-PLAN.md.

## Goal

A complete, professional redesign of the main macOS/iOS surface so it reads
clearly and communicates outcomes: a differentiated study list, model
pickers that show the chosen model with concise non-duplicated captions, an
outcome-first results view that doesn't repeat the top hypothesis verbatim,
honest human-readable status, and a coherent visual hierarchy. Apply the
SwiftUI design skills (`swift-design`, `swiftui-design-principles`,
`swiftui-pro`, `swiftui-view-refactor`, `writing-for-interfaces`).

## Context

Operator (2026-06-05, with screenshot): "the main UI has some layout and
communication issues — crashing text, weird alignment, buried info… a
complete professional UI redesign." Concrete problems observed:

- **Undifferentiated sidebar:** every study shows "New research goal"
  because the title derives from a generic seed goal; the list can't tell
  studies apart. (M16 added titles, but the default seed defeats them.)
- **Pickers hide the choice:** `ModelChoicePicker` shows only "Generator" /
  "Reviewer", not the selected model; the same long strengths caption is
  repeated verbatim under both pickers (buried, redundant).
- **Results duplicate:** the green "Conclusion" block renders the full top
  hypothesis text (truncated mid-word) and the **same text repeats** as the
  first Hypotheses row.
- **Status reads as dev logs:** "Done · 3 hypotheses · 1 repairs · 1 decode
  failures" (also "1 repairs" grammar).
- **Flat hierarchy / alignment:** config, conclusion, tabs, and list stack
  in one long scroll; cramped steppers; no clear altitude between
  configure → run → outcome.

Sequenced **after M20** (provider loading + state cleanup), which fixes the
data feeding the pickers; this milestone is the visual/IA/copy layer on top.
Both are UX; M20 is data-correctness, M21 is presentation.

## Usage Scenarios

### Scenario 1: Tell studies apart

- The sidebar shows a meaningful per-study title (from the goal as entered,
  or an explicit name) plus a secondary line (status/relative time); no two
  unrelated studies look identical.

### Scenario 2: See the model you picked

- Each picker shows the selected model inline ("Generator: Qwen3-4B"); the
  caption is short and only appears once, describing the *current* choice —
  not a duplicated paragraph under every picker.

### Scenario 3: Read the outcome at a glance

- After a run, the view leads with a concise conclusion (a real synthesis,
  not the verbatim top hypothesis), then the ranked hypotheses without
  duplicating the headline; status is plain language ("Done — 3 hypotheses").

## Primary Scope

### Track A — Information architecture + hierarchy (Apps/Shared)

Restructure `StudyDetailView` so the layout has clear altitude: a compact
configuration zone (collapses/condenses once a run exists), then an
outcome-first results region. Fix alignment/spacing to an 8pt rhythm; tidy
the steppers/controls. Use `swiftui-view-refactor` to split the long body
into small dedicated subviews. (`swift-design`, `swiftui-design-principles`.)

### Track B — Pickers + sidebar (Apps/Shared)

`ModelChoicePicker`: show the selected model in the control; render the
strengths/fit caption once, concisely, for the current choice only (no
duplicate paragraphs). `StudiesView`/`StudyRow`: a differentiated title +
clean secondary line; better empty/new-study naming so the list is legible.
(`writing-for-interfaces` for labels.)

### Track C — Results + status copy (Apps/Shared)

The Conclusion block leads with the meta-review synthesis (concise, expand
for full), and the ranked list does not repeat the headline hypothesis
verbatim; long text truncates gracefully with disclosure. Replace dev-log
status with plain, correctly pluralized language. (`writing-for-interfaces`.)

## Definition Of Done

- Sidebar studies are visually distinguishable (no row of identical titles
  for distinct studies); verified on macOS + iOS.
- Each model picker shows the selected model inline; the strengths/fit
  caption appears once and reflects the current choice (no duplicate blocks).
- Results lead with a concise conclusion that is **not** a verbatim copy of
  the first hypothesis; long text truncates with a way to expand.
- Run status copy is plain language and correctly pluralized.
- Layout follows a consistent spacing rhythm; `StudyDetailView` is split
  into small subviews (no single oversized `body`).
- A visual/HIG review pass (`swift-design`) records before/after notes in the
  closeout; no regressions to run/results/inspector/activity behavior.
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M21 tracking + closeout docs land with the final commit.

## Non-Goals

- New features or engine behavior (presentation only).
- The provider/model data-loading + state pruning (that is M20).
- Multi-indicator run progress (separate candidate theme; this may tidy the
  single progress view but does not build the stacked-indicator system).
- A full design-token system / theming overhaul (scope to the main surface).

## Open Questions

- **[?]** Default study naming: keep a derived title but seed new studies
  with an empty goal + inline prompt (so the list shows real goals), vs an
  explicit auto-name. Lean: empty seed + "Untitled" until the goal is typed,
  title tracks the goal's first line until the user overrides.
- **[?]** Whether the config zone collapses to a summary bar after a run, or
  stays expanded. Lean: collapse to a one-line summary with an edit affordance.
- **[?]** Conclusion length/disclosure pattern (lineLimit + "Show more" vs a
  fixed short synthesis). Lean: short synthesis + expandable detail.

## Risk

- **Shared views drive both platforms** — a redesign must stay
  size-class-adaptive (the M15 inspector pane/sheet split must keep working
  on iPhone/iPad/macOS). Mitigation: build + sanity-check both.
- **Scope creep** — "complete redesign" can sprawl. Mitigation: scope to the
  main study surface (list + detail + pickers + results); defer deeper
  theming.

## Scope Class

Medium. Presentation-layer refactor across the main `Apps/Shared` views;
no Kit/engine change. Estimated ~8–12 commits across Tracks A–C.
