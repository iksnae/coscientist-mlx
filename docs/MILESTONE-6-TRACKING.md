# Milestone 6 Tracking

Date: 2026-06-04

Milestone:

```txt
Agent tool-use loop + grounded Generation/Reflection
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
| `ToolRegistry` resolves tools by name and returns nil for unknown names. | Pending | Track A |
| `ToolCallParser` extracts a `{"tool","args"}` object and returns nil when absent. | Pending | Track A |
| The tool-use loop executes a scripted tool call, feeds the observation back, and terminates with a validated typed output. | Pending | Track A |
| A no-tool-call response falls through to the inner one-shot decode with identical output. | Pending | Track A |
| The loop is bounded by `maxToolSteps` and forces a final decode at the cap. | Pending | Track A |
| Generation and Reflection produce grounded output when routed through the grounded router and unchanged output when not. | Pending | Track B |
| `--tools` runs the grounded path; tool calls are recorded in the transcript. | Pending | Track C |
| New behaviour is driven by a test written first (mock backend, no GPU). | Pending | all tracks |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Pending | `git grep` check |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Baseline clean on Apple Silicon (origin/main). |
| `swift test` | Passed | Baseline 107 tests / 22 suites green. |
| `git diff --check` | Pending | — |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| `GroundedDecoder` conforms to `SchemaConstrainedDecoding`. | Accepted | Agents accept it unchanged; final decode reuses existing validate+repair; grounding becomes a routing concern, not an agent concern. |
| Tool-call format = JSON object with a `tool` key. | Accepted | Simplest to parse/prompt; reuses `JSONExtraction` + `JSONValue`; distinguishable from the final answer by the `tool` key. |
| Tools wired only into Generation + Reflection. | Accepted | Highest-value grounding (hypothesis creation + novelty); proves the loop before broadening (per plan Non-Goals). |
