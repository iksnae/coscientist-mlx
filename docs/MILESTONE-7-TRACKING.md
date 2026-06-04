# Milestone 7 Tracking

Date: 2026-06-04

Milestone:

```txt
Hosted per-agent model backing
```

## Status

Complete

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-04 |
| Actual start | 2026-06-04 |
| Actual end | 2026-06-04 |
| Elapsed | same day |
| Scope class | Small |
| Confidence | High |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| `listModels` parses a canned `/models` response into an id list and throws on non-2xx. | Done | `RemoteModelDiscoveryTests` (a574a62) |
| `RoleBackend` maps each role to a local-or-remote choice; builder routes assigned roles to their backend, others to default. | Done | `RoleBackendTests` (3e80b8d) |
| `--list-remote-models` prints the discovered list; `--agent-model role=id` assigns per role; no flags ⇒ today's behavior. | Done | CLI flags (02303e7); `--help` verified. |
| App Providers tab lists hosted models, offers presets + per-agent picker; assignments persist; API key in Keychain. | Done | `SettingsStore`/`SettingsView` (77bb13c); macOS BUILD SUCCEEDED. |
| Remote disabled ⇒ every role resolves to a local decoder (local-first). | Done | `RoleBackendTests.emptyIsAllBase`; `SettingsStore.roleBackends` guards on `remoteReady`. |
| New behaviour is driven by a test written first (mock backend, no GPU). | Done | `RemoteModelDiscoveryTests`, `RoleBackendTests` written before impl. |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Done | `git grep "import MLX" -- '*.swift'` → only adapter + `Package.swift`. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on Apple Silicon. |
| `swift test` | Passed | 123 tests / 26 suites green (+7 vs M6's 116/24). |
| macOS app build | Passed | `xcodebuild … CoScientistDemo` BUILD SUCCEEDED. |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Discovery reuses `remoteBaseURL` + `models`. | Accepted | Mirrors the existing chat path; works for OpenAI-compatible servers. |
| Kit stays free of AICoScientistRemote via an injected remote-decoder factory. | Accepted | Preserves the protocol-only domain layer; the builder takes a `makeRemote` closure. |
| UI uses presets + advanced per-role expander. | Accepted | Common cases need one choice, not seven; avoids Providers-tab sprawl. |
