# Milestone 16 Planning Draft

Date: 2026-06-05

Working name:

```txt
Study title + body + CRUD parity (CloudKit-ready)
```

## Status

Draft. Not yet promoted to MILESTONE-16-PLAN.md.

## Goal

Give a Study a real, editable **title** distinct from its **goal/body**,
show the title in the list, and assure full create/read/update/delete on
both apps. Keep the SwiftData model **CloudKit-ready** (so M17 sync is a
small step) and make `StudyDocument` export/import round-trip the full
study config (it currently drops the M13/M14 model + run-config choices).

## Context

Operator (2026-06-05): "assure Study CRUD across apps; Study should have
title and body, not just request/body." Today `Study.title` is auto-set to
`goal` and never shown (the list shows `goal`); CRUD exists but is
implicit (create via toolbar, delete via swipe, update via autosaved
fields in `StudyDetailView`). `StudyDocument` only carries
`goal/hypothesesPerGeneration/iterations/useRemoteJudge` — it drops the
M13 generator/reviewer choices and the M14 survivors/tournament config.
This milestone also prepares for M17 (iCloud sync): the SwiftData model
must be CloudKit-compatible (optional/defaulted attributes, no unique
constraints, optional relationships) — it already uses defaults; this
milestone verifies + documents that.

## Usage Scenarios

### Scenario 1: Name a study

Expected behavior:

- A study has an editable **Title** (defaults from the goal on first
  creation but is independent thereafter); the sidebar/list shows the
  title; the detail view edits title + goal.

### Scenario 2: CRUD on iPhone and Mac

Expected behavior:

- Create, rename, and delete studies work on both apps; edits autosave;
  no macOS-only gating of core CRUD (import stays macOS-only as before).

### Scenario 3: Share a study faithfully

Expected behavior:

- Exporting then importing a `.coscientist` file preserves the title,
  goal, generator/reviewer choices, and run config (survivors, tournament
  rounds, iterations, hypotheses).

## Primary Scope

### Track A — Title/body model + CRUD (Apps/Shared)

`Study`: keep `title` as a first-class editable field (independent of
`goal`); `StudyRow` shows the title; `StudyDetailView` edits title + goal.
A rename affordance (title field in detail; optional list context-menu
rename). Verify create/delete on both apps. Apply `swiftdata-pro` (keep
attributes optional/defaulted, no `.unique`, for CloudKit) +
`writing-for-interfaces` (Title vs Goal labels).

### Track B — Full `StudyDocument` round-trip (Apps/Shared)

Extend `StudyDocument` to carry title + generator/reviewer (`ModelChoice`)
+ `evolutionTopK`/`tournamentRounds` + iterations/hypotheses, and
`makeStudy()` to restore them. Unit-test the round-trip.

## Definition Of Done

- `Study.title` is editable, defaults from the goal on creation, and is
  shown in the list; the detail view edits title + goal.
- Create / rename / delete work on macOS and iOS (build-verified on both).
- `StudyDocument` round-trips title + model choices + run config;
  unit-tested (encode → decode → `makeStudy` preserves the fields).
- The SwiftData `Study` model is CloudKit-compatible (optional/defaulted
  attributes, no unique constraints) — documented in the closeout for M17.
- New logic is test-first (mock, no GPU); UI verified by building both apps.
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M16 tracking + closeout docs land with the final commit.

## Non-Goals

- iCloud sync itself — that is M17 (this only keeps the model ready).
- New run behavior; this is data-model + CRUD UX.
- iOS study import via document picker (still macOS-only; separate
  follow-up).

## Open Questions

- **Title default.** Derive from the first line of the goal vs a generic
  "New study" until edited. Lean: default to the goal's first line, stay
  independent after.
- **List rename.** Inline rename in the sidebar vs only via the detail
  title field. Lean: detail field now; context-menu rename if cheap.

## Risk

- **SwiftData migration.** Making `title` first-class + any field changes
  must not break existing local studies (defaulted fields; tested decode).

## Scope Class

Small. Model/field clarification + a document round-trip + CRUD
verification; mostly Apps/Shared.

Estimated 3–4 (Track A) + 2–3 (Track B), ~5–7 commits.
