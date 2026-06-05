# Milestone 13 Planning Draft

Date: 2026-06-05

Working name:

```txt
Model selection control-flow — one mental model (macOS)
```

## Status

Ready. Promoted from `docs/MILESTONE-13-PLANNING-DRAFT.md`.

Resolved open questions: the picker offers download proactively and the run
still guards; "Reviewer" = the reflection + tournament roles (the generator
backs generation/evolution/meta-review/ranking).

## Goal

Replace the scattered, invisible-precedence model controls with one clear
mental model on the mac app: **each Study picks a Generator and a Reviewer,
each either on-device or hosted.** Embeddings stay a global on-device
default. Settings shrinks to providers (keys/URLs) + model downloads. Model
pickers show what's actually installed (size, RAM fit, download state) and
let you choose hosted models from the live provider list. After this, a
user can answer "what model runs each part of my study?" from one screen.

## Context

Operator signal (2026-06-05): the user-layer control flow is the weak point
on a strong foundation. Diagnosis (grounded in code): the effective
generator is decided by four controls across two screens — `Study.generatorKey`,
Settings `generatorKey` default, Settings `backend` (mlx/foundation), and
Settings `agentModels` per-agent backing — gated by a `useRemoteJudge`/"use
hosted models" toggle, with a separate overlapping Settings default. Pickers
show the static `ModelCatalog` regardless of install state. "Judge" vs
"generator" vs "backend" vs "hosted" overlap with no clean model. Settled
direction: per-study Generator + Reviewer, each {on-device | hosted}. Apply
the vendored skills: `swiftui-design-principles`, `swiftui-pro`,
`swiftui-view-refactor`, `writing-for-interfaces`, `swiftdata-pro`.

## Usage Scenarios

### Scenario 1: Choose models for a study, in one place

Expected behavior:

- In a Study, a **Generator** control and a **Reviewer** control, each a
  single picker offering on-device catalog models and (when a provider is
  configured) hosted models — labeled clearly, with the effective choice
  visible at a glance.
- Embeddings are not a per-study choice; they use a global on-device default
  (shown read-only / in Settings).

### Scenario 2: Pickers reflect reality

Expected behavior:

- Each on-device option shows downloaded ✓ (with size) or "downloads ~N GB",
  and a RAM-fit hint; an inline action downloads a not-yet-installed model.
- Hosted options come from the provider's fetched model list.

## Primary Scope

### Track A — Unified selection model + model research data (AICoScientistKit + Apps/Shared)

A single `ModelChoice` (on-device catalog key | hosted model id) with a pure
resolver that turns a Study's Generator + Reviewer choices into the engine's
`DecoderRouting` (generation role + reflection/tournament "reviewer" roles),
replacing the `backend` + `agentModels` + `useRemoteJudge` tangle. Pure,
MLX-free, unit-tested. (`swiftdata-pro` for the `Study` model changes;
keep a lightweight migration/back-compat for existing studies.)

Also enrich `CatalogModel` with the research we already collected in
`docs/MODELS.md` — a short **strengths** note and a **tier** (Small / Mid /
Large) per model — and add a pure **compatibility** check: given the
device's physical RAM (`ProcessInfo.physicalMemory`, injected as a value so
it's testable), decide whether a model fits (`minRAMGB`) and how
comfortably. Pure + unit-tested; the data source is `docs/MODELS.md`.

### Track B — Install- and system-aware model picker (Apps/Shared)

A reusable `ModelPicker` that uses the device's RAM to surface **compatible**
models first (and clearly mark ones that won't fit), shows each model's
**strengths + tier + size/RAM** from the research (Track A), its install
state (downloaded ✓ + size / "downloads ~N GB"), and an inline download —
plus hosted models from `RemoteModels.list`. Replaces the bare catalog
`Picker`s. Built per `swiftui-design-principles` (restraint, hierarchy) +
`swiftui-pro`.

### Track C — Settings slim-down + copy (Apps/Shared)

Settings becomes providers (base URL, key, fetch models) + model downloads +
the embedder default only — per-study model choices move to the Study. Rename
and rewrite the copy (Generator / Reviewer, on-device vs hosted) per
`writing-for-interfaces`, removing "judge/backend/hosted models" ambiguity.
Refactor the large `StudyDetailView`/`SettingsView` into small subviews per
`swiftui-view-refactor`.

## Definition Of Done

- `ModelChoice` + the resolver map a Study's Generator + Reviewer choices to
  the engine `DecoderRouting` (on-device default; hosted overrides per role),
  unit-tested; with no hosted provider configured everything resolves
  on-device (local-first).
- The `Study` model stores Generator + Reviewer choices; existing saved
  studies still load (migration/back-compat), unit-tested where logic exists.
- `CatalogModel` carries strengths + tier from `docs/MODELS.md`, and a pure
  compatibility check (model `minRAMGB` vs injected device RAM) returns
  fits/comfort, unit-tested.
- The model picker uses device RAM to surface compatible models first (and
  marks ones that won't fit), shows each model's strengths + tier + size +
  RAM-fit and install state, and offers inline download; hosted models
  appear when a provider is configured.
- Settings no longer sets per-study model choices; its copy names Generator /
  Reviewer and on-device / hosted unambiguously (no "judge/backend").
- macOS app builds and runs the new flow; no engine behavior change beyond
  routing wiring.
- New cross-platform logic is test-first (mock backend, no GPU); UI verified
  by building the app.
- `swift build` clean; `swift test` green; macOS app builds.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M13 tracking + closeout docs land with the final commit.

## Non-Goals

- Run-config exposure (survivors/tournament/tool steps) + results-outcome
  redesign — that is M14.
- iOS — M15 ports this shared UX to iOS.
- New providers/auth beyond the existing API-key model.

## Open Questions

- **Per-study local model download trigger.** Download on first run
  (existing guard) vs. from the picker proactively. Lean: picker offers it,
  run still guards. Delivery detail.
- **Reviewer scope.** "Reviewer" = reflection + tournament (the judge
  roles); evolution/meta-review follow the generator. Confirm at delivery;
  lean reviewer = reflection + tournament.

## Risk

- **SwiftData migration.** Adding Study fields must not break saved studies.
  Mitigate with defaulted new fields + a back-compat decode path
  (`swiftdata-pro`), tested.
- **Scatter removal touching the router.** Keep the pure resolver behind the
  existing `DecoderRouting` seam; verify routing with unit tests before UI.

## Scope Class

Medium-to-Large. A unified selection model + install-aware picker + Settings
slim-down + copy + view refactor. Kept grindable by ordering: pure
resolver/model → picker → Settings/copy.

Estimated 4–6 (Track A) + 3–4 (Track B) + 3–4 (Track C), ~10–14 commits.
