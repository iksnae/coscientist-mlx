# Milestone 20 Planning Draft

Date: 2026-06-05

Working name:

```txt
Provider model loading + Settings state cleanup
```

## Status

Draft. Not yet promoted to MILESTONE-20-PLAN.md.

## Goal

Make hosted (OpenAI-compatible) models appear in the Study Generator/Reviewer
pickers **without a manual Settings refresh**, and bring the app's provider/
model state under control by deleting the dead `SettingsStore` fields left
over from the M13 per-study routing change. Fewer ways to be in a broken or
confusing state; the pickers reflect reality at launch.

## Context

Operator (2026-06-05): "get back to UI/UX; get our app state under control."
Triggered by a concrete bug: hosted models don't show in the Study pickers
until you open Settings → Providers → Refresh.

Root cause: `SettingsStore.fetchedModels` is in-memory only and is populated
**only** by `refreshModels()`, wired **only** to the Settings refresh button.
`ModelChoicePicker` gates its Hosted section on
`store.remoteReady && !store.fetchedModels.isEmpty`, so the list is empty on
every launch and nothing auto-loads or caches it.

Since M13 the engine routes per study via `ModelChoice` (generator/reviewer)
+ `StudyRouting`. That left several `SettingsStore` members with **no live
reader** (verified against `WorkflowRunner`): `backend`, `agentModels`,
`roleBackends`, `applyPreset`/`BackingPreset`, and `generatorKey`
(`WorkflowRunner.downloadPlan` reads `study.generatorKey`, not the store).
`remoteEnabled` is a redundant gate on top of "key + base URL + model
present." `downloadPlan(for:)` also checks `study.generatorKey` (a legacy
default) rather than the actually-selected `study.generator`, so the disk
guard can evaluate the wrong model.

Settled with the operator: one milestone covering both the loading fix and
the pruning; **drop `remoteEnabled`** (ready = key + base URL + model
present); **delete the dead fields and migrate (remove) their stale
UserDefaults keys**; sequence this **ahead of M19** (LAN offload), which
stays drafted.

## Usage Scenarios

### Scenario 1: Hosted models just appear

Expected behavior:

- With a provider configured (base URL + key + model), opening a Study's
  Generator or Reviewer picker shows hosted models immediately — no trip to
  Settings, no manual refresh — on a fresh launch.

### Scenario 2: First-time / not-yet-fetched provider

Expected behavior:

- Before any successful fetch, the picker still offers the configured model
  (e.g. `gpt-4o`) as a hosted choice, and shows a lightweight
  fetching/error state so the user understands what's happening.

### Scenario 3: Clean settings

Expected behavior:

- Settings shows only controls that do something; no dead backend/preset/
  per-agent-backing state. Existing installs don't carry stale persisted
  values for removed fields.

## Primary Scope

### Track A — Auto-load + cache hosted models (Apps/Shared)

- Persist the fetched model list (UserDefaults cache) so pickers populate at
  launch; expose it via `SettingsStore`.
- Auto-refresh when the provider is ready and the list is empty/stale
  (e.g. `ModelChoicePicker`/Study config `.task`, and on provider-field
  change), without blocking the UI; reuse the existing `refreshModels()`.
- Always include the configured default model as a hosted option even before
  a fetch; merge (dedupe) with fetched results.
- Surface fetching/error state in the picker, not only in Settings
  (`writing-for-interfaces`).
- A pure, testable resolver for "what hosted options should the picker show"
  (configured model + cached/fetched list, deduped, readiness-gated) — unit
  tested with fed-in inputs.

### Track B — Delete dead provider/model state (Apps/Shared)

- Remove `SettingsStore.backend`, `agentModels`, `roleBackends`,
  `applyPreset`/`BackingPreset`, and `generatorKey`; **remove their
  persisted UserDefaults keys** on init (one-time migration) so stale values
  don't linger. Apply `swiftdata-pro`/`swiftui-pro`.
- Replace `remoteEnabled` with readiness derived from base URL + key + model
  presence; update `SettingsView` (drop the toggle, keep it coherent) and
  `remoteReady`.
- Fix `WorkflowRunner.downloadPlan(for:)` to evaluate the actually-selected
  `study.generator` (`ModelChoice`) instead of `study.generatorKey`.
- Confirm no remaining references to the removed members compile-fail; build
  both apps.

## Definition Of Done

- Hosted models appear in the Study Generator/Reviewer pickers on a fresh
  launch with a provider configured — no manual refresh; verified by both
  app builds + the resolver unit test.
- The configured model is always offered as a hosted option pre-fetch; the
  cached list survives relaunch.
- `SettingsStore` no longer declares `backend`, `agentModels`,
  `roleBackends`, `applyPreset`/`BackingPreset`, `generatorKey`, or
  `remoteEnabled`; their UserDefaults keys are cleared on launch.
- `downloadPlan(for:)` uses `study.generator`.
- New logic is test-first (mock, no GPU); the pure resolver is unit-tested.
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M20 tracking + closeout docs land with the final commit.

## Non-Goals

- LAN model offload (that is M19).
- New provider types or OAuth sign-in (HF OAuth stays "coming soon").
- Multi-indicator run progress (separate candidate theme).
- Re-architecting `SettingsStore` persistence (still UserDefaults; only
  field set changes).

## Open Questions

- **[?]** Cache freshness: re-fetch on every app launch in the background,
  or only when fields change / cache is older than N. Lean: refresh on
  provider-field change + a background refresh when ready and the cache is
  empty; show cached immediately.
- **[?]** Where the pure resolver lives: a small type in `AICoScientistKit`
  vs a testable static on `SettingsStore`. Lean: Kit (keeps it mock-testable
  and UI-free).

## Risk

- **Removing persisted keys** must not disturb the surviving settings
  (embedder, openAIKey, remoteBaseURL, remoteModel, hfToken). Mitigation:
  only delete the named dead keys; keep the rest; covered by both builds.
- **A hidden reader** of a "dead" field outside `WorkflowRunner`. Mitigation:
  compiler catches references; grep before deleting; both apps build.

## Scope Class

Small–Medium. Mostly `Apps/Shared` + one small Kit resolver + tests.
Estimated 3–4 (Track A) + 3–4 (Track B), ~6–9 commits.
