# Milestone 13 Tracking

Date: 2026-06-05

Milestone:

```txt
Model selection control-flow — one mental model (macOS)
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | TBD |
| Elapsed | TBD |
| Scope class | Medium-to-Large |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| `ModelChoice` + resolver map a Study's Generator + Reviewer to the engine routing (on-device default; hosted overrides reflection+tournament); no provider ⇒ all on-device. | Pending | Track A |
| The `Study` stores Generator + Reviewer choices; existing studies still load (back-compat). | Pending | Track A/C |
| `CatalogModel` carries strengths + tier (from MODELS.md); pure compatibility check (minRAMGB vs injected RAM) unit-tested. | Pending | Track A |
| The picker surfaces compatible-first (marks unfit), strengths + tier + size + RAM-fit + install state, inline download; hosted when configured. | Pending | Track B |
| Settings no longer sets per-study model choices; copy names Generator/Reviewer + on-device/hosted (no "judge/backend"). | Pending | Track C |
| macOS app builds + runs the new flow; no engine behavior change beyond routing wiring. | Pending | Track C |
| New cross-platform logic is test-first (mock, no GPU). | Pending | all tracks |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Pending | `git grep` check |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Pending | — |
| `swift test` | Pending | — |
| macOS app build | Pending | — |
| `git diff --check` | Pending | — |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Per-study Generator + Reviewer (each on-device\|hosted); embeddings global. | Accepted | Single source of truth; kills the 4-control scatter. |
| Reviewer = reflection + tournament; generator backs the rest. | Accepted | Matches the "judge" roles; the rest follow generation. |
| Enrich CatalogModel with MODELS.md strengths/tier + system-RAM compatibility. | Accepted | Operator: surface our model research + show compatible models for the device. |
| Picker offers download; run still guards. | Accepted | Proactive install without removing the safety guard. |
