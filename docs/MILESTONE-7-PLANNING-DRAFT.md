# Milestone 7 Planning Draft

Date: 2026-06-04

Working name:

```txt
Hosted per-agent model backing
```

## Status

Draft. Not yet promoted to MILESTONE-7-PLAN.md.

## Goal

Let each agent role be backed by a chosen model — local catalog key or a
specific hosted model — instead of the current single remote-judge field
that only covers reflection + tournament. Add model discovery
(`GET {baseURL}/models`) so users pick from the provider's real model list
rather than typing an id, and per-role assignment so (for example)
Reflection runs on a strong hosted model while Generation stays local.
This directly makes M6's tool-use loop reliable: weak local tool-calling
can be routed to a capable hosted model per agent.

## Context

Carry-forward from the prior session: *"if we enable a hosted provider,
we should be able to pick their respective models to back the agents,"*
answered **per-agent assignment**. The plumbing already exists —
`RoleDecoderRouter` (`Sources/AICoScientistKit/Engine/DecoderRouting.swift`)
routes any `AgentRole` to a backend via overrides, and `RemoteLanguageModel`
(`Sources/AICoScientistRemote/`) is an OpenAI-compatible adapter. What's
missing is (1) discovering available hosted models and (2) a per-role
backing config surfaced through the CLI and the app's Settings/Providers
tab, which today exposes only `remoteModel` (`Apps/macOS/SettingsStore.swift`).

## Usage Scenarios

### Scenario 1: Discover and assign from the app

Expected behavior:

- The Providers/Settings tab fetches the provider's model list and shows
  it in a picker (no free-text typing required).
- Each agent role has its own backend picker: "Local · <catalog key>" or
  one of the fetched hosted models.
- Assignments persist (UserDefaults) and the secret API key stays in the
  Keychain; nothing breaks when remote is disabled (all roles local).

### Scenario 2: Per-agent backing from the CLI

Expected behavior:

- `swift run aicoscientist --list-remote-models` prints the provider's
  models (uses `OPENAI_API_KEY` + base URL).
- `--agent-model reflection=gpt-4o --agent-model tournament=gpt-4o`
  assigns hosted models per role; unset roles stay on the local default.
- With no `--agent-model` flags, behavior matches today's hybrid routing.

## Primary Scope

### Track A — Model discovery (AICoScientistRemote)

A `listModels(baseURL:apiKey:transport:)` that calls
`GET {baseURL}/models` and returns the normalized id list, reusing the
existing `HTTPTransport` seam. Mock-tested with a canned `/models` JSON
payload (no network).

### Track B — Per-role backing config (AICoScientistKit)

A pure `RoleBackend` config (role → `.local(key)` or `.remote(modelId)`)
and a builder that turns it into a `RoleDecoderRouter` given the
available local + remote decoders. Domain-only, MLX-free, mock-tested —
the engine already consumes `DecoderRouting`, so no engine change.

### Track C — Surfaces (AICoScientistCLI + Apps/macOS)

CLI: `--list-remote-models` and repeatable `--agent-model <role>=<id>`.
App: extend `SettingsStore` with a per-role assignment map and the
fetched model list; add the role pickers to `SettingsView`. Construction
of the router from the assignments at run time in `WorkflowRunner` / the
CLI command.

## Definition Of Done

- `listModels` parses a canned `/models` response into an id list and
  surfaces a clear error on a non-2xx response (mock transport).
- `RoleBackend` maps each role to a local-or-remote choice; the builder
  produces a `RoleDecoderRouter` whose `decoder(for:)` returns the
  assigned backend and the default otherwise.
- `--list-remote-models` prints the discovered list; `--agent-model
  role=id` assigns per role; no flags ⇒ today's behavior.
- App Providers tab lists hosted models in a picker and offers a
  per-agent backend picker; assignments persist; API key stays in
  Keychain.
- Remote disabled ⇒ every role resolves to a local decoder (local-first).
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M7 tracking + closeout docs land with the final commit.

## Non-Goals

- Provider auth flows beyond the existing API-key model — assume an
  OpenAI-compatible base URL + key, as today.
- Caching/refresh policy for the model list — fetch on demand; a manual
  refresh is enough.
- Cost/usage accounting per agent — out of scope; a later concern.
- Making any hosted backend a *requirement* — strictly optional;
  local-first is non-negotiable.

## Open Questions

- **Role granularity in the UI.** Seven per-role pickers may overwhelm
  the Providers tab; a "local / hosted-judge / hosted-all" preset with an
  advanced per-role expander is friendlier. Lean presets + an expander.
- **Default base path for discovery.** Most OpenAI-compatible servers
  expose `/v1/models`; some omit `/v1`. Lean reuse the configured
  `remoteBaseURL` and append `models`, matching the chat path.

## Risk

- **Provider `/models` shape drift.** Non-OpenAI servers vary. Mitigate
  by decoding only `data[].id` defensively and degrading to free-text
  entry when the list is empty/unparseable.
- **Per-role config sprawl.** Mitigate with presets (Track C) so the
  common cases need one choice, not seven.

## Scope Class

Small. Discovery + a pure config builder + thin CLI/app surfaces; the
routing engine seam already exists.

Estimated 2–3 commits (Track A) + 2–3 (Track B) + 3–4 (Track C),
~7–10 commits.
