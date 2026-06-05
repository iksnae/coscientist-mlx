# Milestone 16 Tracking

Date: 2026-06-05

Milestone:

```txt
Study title + body + CRUD parity (CloudKit-ready)
```

## Status

In progress

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | — |
| Elapsed | — |
| Scope class | Small |
| Confidence | High |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| `Study.title` is editable, defaults from the goal's first line on creation, and is shown in the list; detail edits title + goal. | Pending | |
| Create / rename / delete work on macOS and iOS (build-verified on both). | Pending | |
| `StudyDocument` round-trips title + model choices + run config; unit-tested (encode → decode preserves the fields). | Pending | |
| The SwiftData `Study` model is CloudKit-compatible (optional/defaulted attributes, no unique constraints) — documented for M17. | Pending | |
| New logic is test-first (mock, no GPU); UI verified by building both apps. | Pending | |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Pending | |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | — | |
| `swift test` | — | |
| macOS app build | — | |
| iOS app build | — | |
| `git diff --check` | — | |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| Extract a pure `StudyConfig` into the Kit; test the round-trip there. | Accepted | `Study`/`StudyDocument` live in the app target (outside `swift test`); the regression-prone Codable/field-coverage logic belongs in the testable Kit. |
| Title defaults from the goal's first line, independent after. | Accepted | Per resolved plan decision. |
| `StudyDocument` nests `StudyConfig` with a legacy flat-decode fallback. | Accepted | Faithful new round-trip without breaking older `.coscientist` files. |
