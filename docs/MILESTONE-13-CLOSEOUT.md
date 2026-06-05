# Milestone 13 Closeout

Date: 2026-06-05

Milestone:

```txt
Model selection control-flow — one mental model (macOS)
```

## Status

Complete.

## Delivered

### Track A — Unified selection model + model research (AICoScientistKit)

- `ModelChoice` (`.onDevice` / `.hosted`, with kind/id helpers for storage)
  and `StudyRouting.router` (`Sources/AICoScientistKit/Engine/StudyRouting.swift`):
  a study's **Generator** backs generation/evolution/ranking/meta-review;
  its **Reviewer** backs reflection + tournament. Replaces the
  backend + per-agent-backing + hosted-toggle tangle. Pure, unit-tested.
- `CatalogModel` enriched with **tier** + **strengths** from
  `docs/MODELS.md`, plus a pure `fit(deviceRAMGB:)` compatibility check
  (insufficient / tight / comfortable) with tolerant Codable. Unit-tested.

### Track B — Install- and system-aware picker (Apps/Shared)

- `ModelChoicePicker` (`Apps/Shared/ModelChoicePicker.swift`): on-device
  models listed **compatible-first** (device RAM via `ProcessInfo`), each
  showing tier + size + ✓downloaded, with a caption surfacing the model's
  strengths + RAM-fit + install state; hosted models appear when a provider
  is configured. Replaces the bare catalog `Picker`.

### Track C — Per-study controls, slim Settings, copy (Apps/Shared)

- `Study` gains `generator`/`reviewer` (kind/id fields + computed
  `ModelChoice`; existing studies migrate to defaults). `WorkflowRunner`
  builds the engine router via `StudyRouting`, pre-loading distinct
  on-device models and falling back hosted→local when no provider is
  configured (local-first).
- `StudyDetailView` shows **Generator** + **Reviewer** pickers (replacing the
  single model picker + the "use hosted models" toggle).
- `SettingsView` slimmed to the on-device embedder default + catalog/
  downloads + the hosted provider (key/base/refresh) that feeds the picker.
  The per-study generator default, the inference-backend picker, and the
  per-agent backing section are gone; copy names Generator/Reviewer and
  on-device/hosted (no "judge/backend"), per `writing-for-interfaces`.

## Validation

```txt
swift build                                   # clean on Apple Silicon
swift test                                    # 143 tests / 33 suites green (+5)
xcodebuild … -scheme CoScientistDemo          # macOS app BUILD SUCCEEDED
xcodebuild … -scheme CoScientistApp …iOS Sim  # iOS app BUILD SUCCEEDED (shared views unbroken)
git grep "import MLX" -- '*.swift'            # only AICoScientistMLX (+ Package.swift comment)
git diff --check                              # whitespace clean
```

## Retrospective

What worked:

- One resolver (`StudyRouting`) collapsed four scattered controls into a
  per-study Generator + Reviewer with explicit, testable routing; the
  `DecoderRouting` seam meant no engine change.
- Surfacing the `docs/MODELS.md` research (tier + strengths) + a device-RAM
  fit check turned the picker from a flat list into a guided choice
  (compatible-first, strengths in the caption) — the operator's ask.
- Because the views live in `Apps/Shared`, iOS inherited the redesign and
  still builds; M15 only needs iOS-specific polish.
- The vendored skills shaped it: `swiftui-design-principles` (restraint,
  one mental model), `writing-for-interfaces` (Generator/Reviewer copy),
  `swiftdata-pro` (kind/id storage + back-compat).

What to improve:

- `StudyDocument` (export/import) doesn't yet carry the new generator/
  reviewer choices (still the legacy `generatorKey`/`useRemoteJudge`) — an
  imported study resets to default models. Carry-forward.
- Apple Foundation Models is temporarily not selectable from the new picker
  (on-device = MLX catalog only); the FM backend code remains. Carry-forward:
  add FM as an on-device option in the picker.
- `SettingsStore` still holds now-unused fields (`backend`, `agentModels`,
  presets, `generatorKey` default); dead code to prune later.
- Verified by build; no launched-run UI verification.

Carry forward (M14):

- M14 — run config (survivors/tournament/tool steps) + results-outcome
  header (drafted).
- `StudyDocument` round-trips generator/reviewer; FM in the picker; prune
  unused `SettingsStore` fields.
