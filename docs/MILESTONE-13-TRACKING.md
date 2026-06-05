# Milestone 13 Tracking

Date: 2026-06-05

Milestone:

```txt
Model selection control-flow — one mental model (macOS)
```

## Status

Complete

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | 2026-06-05 |
| Elapsed | same day |
| Scope class | Medium-to-Large |
| Confidence | Medium |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| `ModelChoice` + resolver map a Study's Generator + Reviewer to the engine routing (on-device default; hosted overrides reflection+tournament); no provider ⇒ all on-device. | Done | `StudyRoutingTests` (9294218); `WorkflowRunner` sanitizes hosted→local when no provider |
| The `Study` stores Generator + Reviewer choices; existing studies still load (back-compat). | Done | `Study` kind/id fields + computed `generator`/`reviewer` (023cb5c); defaulted fields migrate cleanly |
| `CatalogModel` carries strengths + tier (from MODELS.md); pure compatibility check (minRAMGB vs injected RAM) unit-tested. | Done | `StudyRoutingTests.compatibility` + `.researchData` (9294218) |
| The picker surfaces compatible-first (marks unfit), strengths + tier + size + RAM-fit + install state, inline download; hosted when configured. | Done | `ModelChoicePicker` (023cb5c); compatible-first sort + strengths caption + ✓downloaded/size + hosted section |
| Settings no longer sets per-study model choices; copy names Generator/Reviewer + on-device/hosted (no "judge/backend"). | Done | `SettingsView` slim-down (db9664a) |
| macOS app builds + runs the new flow; no engine behavior change beyond routing wiring. | Done | macOS BUILD SUCCEEDED; iOS BUILD SUCCEEDED (shared views unbroken) |
| New cross-platform logic is test-first (mock, no GPU). | Done | `StudyRoutingTests` written before impl. |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Done | `git grep` → only `Package.swift` comment. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on Apple Silicon. |
| `swift test` | Passed | 143 tests / 33 suites green (+5). |
| macOS app build | Passed | `xcodebuild … CoScientistDemo` BUILD SUCCEEDED. |
| iOS app build | Passed | `xcodebuild … CoScientistApp` BUILD SUCCEEDED (shared redesign unbroken). |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Per-study Generator + Reviewer (each on-device\|hosted); embeddings global. | Accepted | Single source of truth; kills the 4-control scatter. |
| Reviewer = reflection + tournament; generator backs the rest. | Accepted | Matches the "judge" roles; the rest follow generation. |
| Enrich CatalogModel with MODELS.md strengths/tier + system-RAM compatibility. | Accepted | Operator: surface our model research + show compatible models for the device. |
| Picker offers download; run still guards. | Accepted | Proactive install without removing the safety guard. |
