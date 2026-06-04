# Milestone 8 Tracking

Date: 2026-06-04

Milestone:

```txt
Apple Foundation Models backend (native tool calling)
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-04 |
| Actual start | TBD |
| Actual end | TBD |
| Elapsed | TBD |
| Scope class | Small |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Package builds without Foundation Models (gates compile it out) and with it. | Pending | Track B |
| `AgentTool` → native `Tool` mapping unit-tested via a seam/mock (no device). | Pending | Track A |
| `--backend foundation` selects the adapter where available; hidden/no-op where not; `--backend mlx` unchanged. | Pending | Track C |
| MLX remains the default; no path makes Foundation Models required. | Pending | Track B/C |
| Real FM inference lives only in an opt-in integration path. | Pending | Track B |
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
| New gated target `AICoScientistFoundationModels`. | Accepted | Quarantines `import FoundationModels`; keeps the dependency optional (mirrors the MLX rule). |
| Structured output routes through the existing decoder, not FM guided-gen. | Accepted | One code path; FM guided-gen is a later optimization. |
