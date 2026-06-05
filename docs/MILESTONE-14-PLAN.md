# Milestone 14 Planning Draft

Date: 2026-06-05

Working name:

```txt
Run config + results outcome (macOS)
```

## Status

Ready. Promoted from `docs/MILESTONE-14-PLANNING-DRAFT.md`.

Resolved: expose raw values + sane defaults (no presets yet). Expose
**survivors (evolutionTopK)** + **tournament size** in the app (both have a
real run effect); **defer tool-steps** from the app UI — the app doesn't run
the tool-use loop yet, so the control would be inert (carry-forward when
tools are app-enabled). Empty meta-review ⇒ the outcome shows the top
hypothesis alone.

## Goal

Surface the hidden run-time parameters and make a finished study state its
outcome. Today `EngineConfiguration` defaults (`tournamentSize`,
`evolutionTopK` — which decides how many hypotheses survive — and tool
steps) are applied at run time but never shown; and results are a ranked
list with no clear conclusion. M14 adds an Advanced run-config section to the
Study and a results header that states the answer (top hypothesis +
meta-review synthesis) above the detail.

## Context

Operator signal (2026-06-05) + M13 carry-forward. Grounded: `WorkflowRunner`
builds the engine with `tournamentSize: 8` and `evolutionTopK: 3` defaults
the user can't see or change (`evolutionTopK` silently collapses the pool to
3 survivors); `maxToolSteps: 4` likewise. `StudyDetailView` shows ranked
hypotheses + tabs but never surfaces `snapshot.metaReviewSummary` or frames
the top hypothesis as the conclusion; the status line is metrics. Settled:
full Advanced section with plain copy; a results outcome header. Apply
`swiftui-design-principles` (hierarchy, restraint), `writing-for-interfaces`
(plain parameter + outcome copy), `swiftui-view-refactor`, `swiftdata-pro`.

## Usage Scenarios

### Scenario 1: Tune a run, understandably

Expected behavior:

- A Study "Advanced" section (collapsed by default) exposes survivors
  (evolutionTopK), tournament size, and tool steps, each with a one-line
  plain explanation and a sane default; values persist on the Study and are
  applied to the run.

### Scenario 2: See the outcome

Expected behavior:

- A finished study opens with an outcome header: the top hypothesis stated as
  the conclusion + the meta-review synthesis, then the ranked list / inspector
  below. The status communicates outcome, not just metrics.

## Primary Scope

### Track A — Run config on the Study (Apps/Shared + Kit wiring)

Add `evolutionTopK` (survivors), `tournamentSize`, and `maxToolSteps` to the
`Study` model (defaulted, back-compat) and thread them through
`WorkflowRunner` into `EngineConfiguration` (+ the tool-use loop). A
collapsed Advanced section with plain copy + defaults. (`swiftdata-pro` for
the model change; `writing-for-interfaces` for the copy.)

### Track B — Results outcome (Apps/Shared)

A results header stating the conclusion: the top hypothesis framed as the
answer + `snapshot.metaReviewSummary` synthesis, with a clear finished-state
status. The ranked list + inspector remain below. Built per
`swiftui-design-principles` (clear hierarchy: outcome first) and refactored
per `swiftui-view-refactor`; outcome copy per `writing-for-interfaces`.

## Definition Of Done

- The `Study` stores survivors / tournament size / tool steps (defaulted,
  existing studies still load), and `WorkflowRunner` applies them to the
  engine — verified by a test that the built `EngineConfiguration` reflects
  the Study's values.
- The Advanced section exposes the three params with plain one-line copy and
  sane defaults; collapsed by default.
- A finished study shows an outcome header (top hypothesis as conclusion +
  meta-review synthesis); empty/running states handled.
- No engine behavior change beyond honoring the now-exposed config.
- New logic is test-first (mock, no GPU); UI verified by building the app.
- `swift build` clean; `swift test` green; macOS app builds.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M14 tracking + closeout docs land with the final commit.

## Non-Goals

- Model selection (M13) and iOS (M15).
- New engine phases or metrics — surface existing config + output only.
- GPU cache cap exposure — handled as hardening in the iOS milestone (M15).

## Open Questions

- **Advanced defaults vs. profile.** Whether to offer presets (quick / deep)
  on top of raw values. Lean raw values + sane defaults now; presets later.
- **Outcome when meta-review is empty.** Fall back to the top hypothesis
  alone. Lean: show top hypothesis; show synthesis when present.

## Risk

- **Config sprawl confusing users.** Mitigate: collapsed Advanced, plain
  one-line copy per param (`writing-for-interfaces`), good defaults.
- **SwiftData migration.** Defaulted new fields + back-compat decode
  (`swiftdata-pro`), tested.

## Scope Class

Small-to-Medium. Study fields + run wiring + an Advanced section + a results
header; reuses existing snapshot data.

Estimated 3–4 (Track A) + 3–4 (Track B), ~6–8 commits.
