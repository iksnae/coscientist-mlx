# Milestone 7 Tracking

Date: 2026-06-04

Milestone:

```txt
Hosted per-agent model backing
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-04 |
| Actual start | 2026-06-04 |
| Actual end | TBD |
| Elapsed | TBD |
| Scope class | Small |
| Confidence | High |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| `listModels` parses a canned `/models` response into an id list and throws on non-2xx. | Pending | Track A |
| `RoleBackend` maps each role to a local-or-remote choice; builder routes assigned roles to their backend, others to default. | Pending | Track B |
| `--list-remote-models` prints the discovered list; `--agent-model role=id` assigns per role; no flags ⇒ today's behavior. | Pending | Track C |
| App Providers tab lists hosted models, offers presets + per-agent picker; assignments persist; API key in Keychain. | Pending | Track C |
| Remote disabled ⇒ every role resolves to a local decoder (local-first). | Pending | Track B/C |
| New behaviour is driven by a test written first (mock backend, no GPU). | Pending | all tracks |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Pending | `git grep` check |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Pending | — |
| `swift test` | Pending | — |
| `git diff --check` | Pending | — |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Discovery reuses `remoteBaseURL` + `models`. | Accepted | Mirrors the existing chat path; works for OpenAI-compatible servers. |
| Kit stays free of AICoScientistRemote via an injected remote-decoder factory. | Accepted | Preserves the protocol-only domain layer; the builder takes a `makeRemote` closure. |
| UI uses presets + advanced per-role expander. | Accepted | Common cases need one choice, not seven; avoids Providers-tab sprawl. |
