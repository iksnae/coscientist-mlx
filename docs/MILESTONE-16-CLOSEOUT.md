# Milestone 16 Closeout

Date: 2026-06-05

Milestone:

```txt
Study title + body + CRUD parity (CloudKit-ready)
```

## Status

Complete.

## Delivered

### Track B — Pure StudyConfig + faithful StudyDocument round-trip

- `StudyConfig` (`Sources/AICoScientistKit/Engine/StudyConfig.swift`): a
  pure, persistence-free value type carrying the full portable study
  config — `title`, `goal`, generator/reviewer `ModelChoice`,
  `hypothesesPerGeneration`, `iterations`, `evolutionTopK`,
  `tournamentRounds`, `useRemoteJudge`. `Codable` with a **tolerant**
  decoder (every new field defaults when absent) and a
  `defaultTitle(forGoal:)` helper (goal's first non-empty line, trimmed;
  `"New study"` when empty). Unit-tested in the Kit (`StudyConfigTests`):
  full encode → decode field preservation, legacy-document defaults, and
  the title-from-goal rule.
- `Study` (`Apps/Shared/Study.swift`) gains a `config: StudyConfig`
  bridge (get projects the stored fields; set applies a config back).
- `StudyDocument` now carries `StudyConfig` + `snapshot` (it previously
  dropped the M13 model choices and the M14 survivors/tournament config).
  Decoding is tolerant: it reads the nested `config`, falling back to the
  legacy flat layout so older `.coscientist` files still import.

### Track A — Editable title + CRUD parity (Apps/Shared)

- `Study.title` is first-class and editable, defaulting from the goal's
  first line on creation (via `StudyConfig.defaultTitle`) and independent
  thereafter (editing the goal no longer overwrites the title).
- `StudyRow` shows the **title** (was the goal); `StudyDetailView` edits
  title + goal with autosave (both bump `updatedAt`).
- Rename affordance: a context-menu **Rename** on the sidebar row (alert
  with a title field), plus the detail title field — on both apps.
- Create / delete already shared (`StudiesView`); verified on macOS + iOS.
  Export filenames now use the title.

### CloudKit readiness (for M17)

- The SwiftData `Study` model is CloudKit-compatible: every stored
  attribute has a default value, `resultData` is optional (`Data?`), there
  are **no** `@Attribute(.unique)` constraints and no relationships. M17
  can enable a CloudKit private-DB container without a schema change.

## Validation

```txt
swift build                                   # clean on Apple Silicon
swift test                                    # 152 tests / 36 suites green (+4)
xcodebuild … -scheme CoScientistDemo          # macOS app BUILD SUCCEEDED
xcodebuild … -scheme CoScientistApp …iOS Sim  # iOS app BUILD SUCCEEDED
git grep "import MLX" -- '*.swift'            # only under AICoScientistMLX/
git diff --check                              # whitespace clean
```

The round-trip is unit-tested at the `StudyConfig` (Codable) layer in the
Kit — the regression-prone surface. The thin `Study ⇄ StudyConfig` mapping
and the document wrapper are verified by building both apps.

## Retrospective

What worked:

- Extracting `StudyConfig` into the Kit moved the field-coverage +
  `Codable` correctness (the part that silently drops config) into the
  fast, mock-free `swift test` path, even though `Study`/`StudyDocument`
  live in the app target.
- A tolerant decoder on both `StudyConfig` and `StudyDocument` made the
  format change additive — new round-trip fidelity without breaking older
  exports.
- Title-as-first-line keeps the zero-friction "just type a goal" flow
  while giving studies a real, editable name in the list.

What to improve:

- Inline sidebar rename uses an alert text field rather than true
  in-place list editing; fine cross-platform, but a rename-in-row would
  feel more native on macOS.
- `Study.generatorKey` remains as a legacy field (superseded by the
  generator `ModelChoice`); a later cleanup could drop it.

Carry forward:

- **M17 — iCloud sync (SwiftData + CloudKit).** The model is now
  CloudKit-ready; M17 adds signing (team `G98TZJ75HL`) + the private-DB
  container. Hard dependency on the operator's Apple Developer account /
  iCloud container at grind time.
- **M18 — Distributed compute feasibility spike** (drafted).
- Candidate themes: multi-indicator run progress; model registry sync;
  parity-test harness; native FM tool calling.
- Standing: prune unused `SettingsStore` fields; thermal reason string;
  iOS study import via document picker (still macOS-only).
