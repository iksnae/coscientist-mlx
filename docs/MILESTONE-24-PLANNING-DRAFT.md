# Milestone 24 Planning Draft

Date: 2026-06-05

Working name:

```txt
Results-primary Study detail + Configure sheet
```

## Status

Draft. Not yet promoted to MILESTONE-24-PLAN.md.

## Goal

Implement the **Results-first** Study detail and move configuration into a
**Configure sheet**, per `docs/DESIGN-WIREFRAMES.md` §2/§4 and the mockups.
The Study's data + outcome lead; configuration recedes — the structural fix
for "config dominates the screen."

## Context

Builds on M23 tokens and the M22 `RunState`. Today `StudyDetailView` is a
config-first scrolling header (even with the M21 collapse) followed by
results. The IA + wireframes + mockups specify the target: header → Conclusion
→ lenses → ranked hypotheses; config (Name/Goal/models/params/Advanced) in a
sheet. Second of the build batch.

## Usage Scenarios

### Scenario 1: Outcome leads
- Opening a finished study shows the **Conclusion** first (synthesis + a
  truncated, expandable top hypothesis + top Elo), then the ranked
  Hypotheses; the config is just a one-line summary chip + Configure button.

### Scenario 2: Configure in a sheet
- Tapping **Configure** opens a sheet with **Name** (title), **Goal**,
  **Generator/Reviewer**, **Hypotheses/Iterations**, and **Advanced**
  (Survivors, Tournament rounds); **Run** dismisses and starts the run.

## Primary Scope

### Track A — Configure sheet (Apps/Shared)
Extract configuration into a `ConfigureStudySheet`: Name (title; auto-tracks
goal via `StudyTitle`), Goal, Generator/Reviewer (`ModelChoicePicker`),
Hypotheses/Iterations steppers, Advanced disclosure; Cancel / Run. Presented
as a sheet (medium on iPad/macOS, full on iPhone). Apply `swiftui-view-refactor`.

### Track B — Results-primary detail
Restructure `StudyDetailView`: compact header (title inline + status line +
config-summary chip + Run/Stop + Configure + Export) → Conclusion block →
lens switch [Hypotheses | Graph | Charts | Activity] → ranked hypotheses →
Inspector. Live state shows `RunProgressView`. Tokens from M23;
`writing-for-interfaces` for copy.

### Track C — Wire to RunState + parity
Drive header/conclusion/lenses from the M22 `RunState`/snapshot; keep the
M15 size-class-adaptive inspector (pane vs sheet). No behavior regressions to
run/results/inspector/activity.

## Definition Of Done

- Study detail is **Results-first**; configuration lives in a **Configure
  sheet** that includes the **Name/title** field; no config block dominates.
- Conclusion leads (synthesis + truncated/expandable top hypothesis); ranked
  hypotheses below; lenses switch; inspector works (pane/sheet by size class).
- Matches the wireframe (§2/§4) + mockups; uses M23 tokens.
- Pure helpers (if any new derived view-state) are unit-tested.
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M24 tracking + closeout land with the final commit.

## Non-Goals

- Models destination / nav-shell changes (M25).
- Inspector deep content + viz animation polish (M26) beyond keeping parity.
- New engine behavior.

## Open Questions

- **[?]** Configure presentation on macOS: sheet vs popover from the
  Configure button. Lean: sheet for parity across platforms.

## Risk

- **Large view refactor, verified by build only (no live run here).**
  Mitigation: keep `RunState` accessors stable; land Configure sheet first,
  then restructure; smoke-test both apps; operator device check at closeout.

## Scope Class

Medium.
