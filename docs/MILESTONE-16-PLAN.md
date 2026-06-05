# Milestone 16 Plan

Date: 2026-06-05

Working name:

```txt
Study title + body + CRUD parity (CloudKit-ready)
```

## Status

Ready.

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

## Primary Scope (Execution Order)

1. **Track B first (pure, testable).** Extract a pure `StudyConfig` value
   type into `AICoScientistKit` carrying the full portable config (title,
   goal, generator/reviewer `ModelChoice`, hypothesesPerGeneration,
   iterations, evolutionTopK, tournamentRounds, useRemoteJudge), `Codable`
   with tolerant field defaults. Failing test first
   (`StudyConfigTests`: encode → decode preserves every field; a legacy
   JSON missing the new fields decodes with sane defaults). Then rewire
   `StudyDocument` to carry `StudyConfig` + `snapshot`, with a legacy
   flat-document decode fallback, and map `Study` ⇄ `StudyConfig`.
2. **Track A (UI/CRUD).** `Study.title` first-class + default from the
   goal's first line on creation; `StudyRow` shows the title;
   `StudyDetailView` edits title + goal (autosave); list context-menu
   rename. Verify create/rename/delete on both apps.
3. Build macOS + iOS; `swift build` + `swift test` green;
   `git diff --check` clean; closeout + tracking land with the final commit.

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

## Resolved Decisions

- **Title default.** Decided: on creation, derive the title from the
  goal's first line (trimmed); it stays independent thereafter (editing
  the goal does not overwrite an existing title).
- **List rename.** Decided: rename via the detail title field, **and** a
  list context-menu "Rename" affordance (cheap — a focused title field /
  inline alert), on both apps.
- **Document format.** Decided: `StudyDocument` carries a nested
  `StudyConfig` + `snapshot`, with a tolerant decode that falls back to
  the legacy flat fields so older `.coscientist` files still import.

## Risk

- **SwiftData migration.** Making `title` first-class + any field changes
  must not break existing local studies (defaulted fields; tested decode).

## Scope Class

Small. Model/field clarification + a document round-trip + CRUD
verification; mostly Apps/Shared.

Estimated 3–4 (Track A) + 2–3 (Track B), ~5–7 commits.
