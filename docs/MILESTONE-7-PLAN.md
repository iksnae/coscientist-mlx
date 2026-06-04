# Milestone 7 Plan

Date: 2026-06-04

Working name:

```txt
Hosted per-agent model backing
```

## Status

Ready. Promoted from `docs/MILESTONE-7-PLANNING-DRAFT.md`.

## Goal

Let each agent role be backed by a chosen model — a local catalog key or a
specific hosted model — instead of the single remote-judge field that only
covers reflection + tournament. Add model discovery (`GET {baseURL}/models`)
so users pick from the provider's real model list rather than typing an id,
and per-role assignment so (e.g.) Reflection runs on a strong hosted model
while Generation stays local. This de-risks M6's tool-use loop: weak local
tool-calling can be routed per-role to a capable hosted model.

## Design (resolved open questions)

- **Discovery path:** reuse the configured `remoteBaseURL` and append
  `models` (mirrors the existing `chat/completions` path construction in
  `RemoteLanguageModel`). Decode `data[].id` defensively; an empty/unparseable
  list degrades to free-text entry.
- **UI granularity:** presets — *all local* / *hosted judge* (reflection +
  tournament) / *hosted all* — plus an advanced per-role expander, so the
  common cases are one choice, not seven.
- **Reuse the existing seam:** `RoleDecoderRouter` already routes per role;
  M7 adds a pure config (`RoleBackend`) + a builder that turns assignments
  into that router. No engine change.

## Primary Scope (Execution Order)

Pure + testable first (discovery, config), then the surfaces that consume
them. Each step is independently commit-able.

### Track A — Model discovery (AICoScientistRemote)

`listModels(baseURL:apiKey:transport:)` performing `GET {baseURL}/models`,
reusing the `HTTPTransport` seam, returning a normalized `[String]` of ids.
Non-2xx → a clear thrown error. Mock-tested with a canned `/models` payload.

### Track B — Per-role backing config (AICoScientistKit)

A pure `RoleBackend` (role → `.local(key)` or `.remote(modelId)`) and a
builder `func router(default:roleBackends:makeRemote:)` (or similar) that
produces a `RoleDecoderRouter`: each assigned role resolves to its backend,
others to the default. MLX-free, mock-tested. The remote-decoder factory is
injected so Kit stays free of `AICoScientistRemote`.

### Track C — Surfaces (AICoScientistCLI + Apps/macOS)

- CLI: `--list-remote-models` (prints discovered ids) and repeatable
  `--agent-model <role>=<id>` (assigns per role; unset roles stay local).
- App: extend `SettingsStore` with a per-role assignment map + the fetched
  model list; add presets + an advanced per-role picker to `SettingsView`;
  build the router from assignments in `WorkflowRunner`.

## Definition Of Done

- `listModels` parses a canned `/models` response into an id list and throws
  a clear error on a non-2xx response (mock transport).
- `RoleBackend` maps each role to a local-or-remote choice; the builder's
  `decoder(for:)` returns the assigned backend and the default otherwise.
- `--list-remote-models` prints the discovered list; `--agent-model role=id`
  assigns per role; no flags ⇒ today's behavior.
- App Providers tab lists hosted models in a picker, offers presets + a
  per-agent picker; assignments persist; the API key stays in the Keychain.
- Remote disabled ⇒ every role resolves to a local decoder (local-first).
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M7 tracking + closeout docs land with the final commit.

## Non-Goals

- Provider auth beyond the existing API-key model.
- List caching/refresh policy — fetch on demand; manual refresh suffices.
- Per-agent cost/usage accounting.
- Making any hosted backend a requirement — strictly optional; local-first
  is non-negotiable.
