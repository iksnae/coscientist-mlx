# Milestone 7 Closeout

Date: 2026-06-04

Milestone:

```txt
Hosted per-agent model backing
```

## Status

Complete.

## Delivered

### Track A — Model discovery (AICoScientistRemote)

- `RemoteModels.list(baseURL:apiKey:transport:)`
  (`Sources/AICoScientistRemote/RemoteModelCatalog.swift`): `GET
  {baseURL}/models`, decoding `data[].id` defensively; non-2xx throws a
  clear `AgentError`; empty list returns `[]`. Reuses the `HTTPTransport`
  seam — unit-tested without networking.

### Track B — Per-role backing config (AICoScientistKit)

- `RoleBackend` (`.local` / `.remote(id)`) and
  `RoleDecoderRouter.backed(default:backends:makeRemote:)`
  (`Sources/AICoScientistKit/Engine/RoleBackend.swift`): remote-assigned
  roles resolve to `makeRemote(id)`, everything else to the base. No
  assignments ⇒ all local (local-first). Kit stays free of
  `AICoScientistRemote` via the injected `makeRemote` closure.

### Track C — Surfaces (AICoScientistCLI + Apps/macOS)

- CLI: `--list-remote-models` (prints discovered ids), repeatable
  `--agent-model <role>=<id>`, and `--base-url`. `--remote-judge` is now
  shorthand for reflection + tournament backings. Composes with `--tools`.
- App: `SettingsStore` gains persisted per-role assignments, a fetched
  model list, presets (all-local / hosted-judge / hosted-all), and
  `roleBackends`. The Providers tab adds Refresh + a model picker and a
  per-agent backing section (presets + an advanced per-role expander).
  `WorkflowRunner` builds the router via `RoleDecoderRouter.backed`,
  keeping the classic judge split as the default when nothing is assigned.

Not in scope despite being adjacent: provider auth beyond API keys, list
caching/refresh policy, per-agent cost accounting, and per-role *local*
model selection (one local model is loaded; `.local` means "use it").

## Validation

```txt
swift build                          # clean on Apple Silicon
swift test                           # 123 tests / 26 suites green (+7 vs 116/24)
xcodebuild … -scheme CoScientistDemo # macOS app BUILD SUCCEEDED
git grep "import MLX" -- '*.swift'   # only AICoScientistMLX + Package.swift
git diff --check                     # whitespace clean
```

Real hosted runs (live `GET /models` + per-agent remote inference) are an
opt-in manual step, not part of the default `swift test` path.

## Retrospective

What worked:

- The `RoleDecoderRouter` seam from earlier milestones meant per-agent
  backing was a pure config + builder — no engine change, and it composes
  cleanly with M6's grounded routing.
- Injecting `makeRemote` as a closure kept the discovery/decoder
  construction in the app/CLI while the routing logic stayed pure in Kit
  (no `AICoScientistRemote` dependency leaking into the domain layer).
- Presets over the configured model keep the common cases one click,
  with the per-role expander for power users.

What to improve:

- A stale pre-rename `CoScientistApp.xcodeproj` shadowed the real
  `CoScientist.xcodeproj` and broke the app build mid-milestone; fixed by
  removing it + regenerating, and documented in the README so it can't
  recur. Worth a `bootstrap.sh` if it shows up again.
- `--agent-model` parsing has no unit test (no CLI test target, per repo
  convention); the pure discovery + routing logic carries coverage.

Carry forward (M8 candidates):

- Foundation Models backend — map `AgentTool` to Apple's native tool
  calling; the per-role router can already route a role to it (M8, drafted).
- Optional `bootstrap.sh` for one-command app project setup.
- A CLI test target so flag parsing (`--agent-model`) is unit-covered.
