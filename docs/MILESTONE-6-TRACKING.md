# Milestone 6 Tracking

Date: 2026-06-04

Milestone:

```txt
Agent tool-use loop + grounded Generation/Reflection
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
| `ToolRegistry` resolves tools by name and returns nil for unknown names. | Done | `ToolUseTests.registryResolves` (4e0489b) |
| `ToolCallParser` extracts a `{"tool","args"}` object and returns nil when absent. | Done | `ToolUseTests.parserExtractsAndRejects` (4e0489b) |
| The tool-use loop executes a scripted tool call, feeds the observation back, and terminates with a validated typed output. | Done | `ToolUseTests.loopGroundsFinalDecode` (4e0489b) |
| A no-tool-call response falls through to the inner one-shot decode with identical output. | Done | `ToolUseTests.noToolCallIsIdentical` (4e0489b) |
| The loop is bounded by `maxToolSteps` and forces a final decode at the cap. | Done | `ToolUseTests.boundedBySteps` (4e0489b) |
| Generation and Reflection produce grounded output when routed through the grounded router and unchanged output when not. | Done | `GroundedRoutingTests` (02be9aa) |
| `--tools` runs the grounded path; tool calls are recorded in the transcript. | Done | CLI `--tools` + observer print (b5a4140); `--help` verified. Real-model run is opt-in. |
| New behaviour is driven by a test written first (mock backend, no GPU). | Done | `ToolUseTests`, `GroundedRoutingTests` written before impl. |
| `import MLX*` appears only under `Sources/AICoScientistMLX/`. | Done | `git grep "import MLX" -- '*.swift'` → only adapter + `Package.swift` manifest. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on Apple Silicon (b5a4140). |
| `swift test` | Passed | 116 tests / 24 suites green (+9 vs. baseline 107/22). |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| `GroundedDecoder` conforms to `SchemaConstrainedDecoding`. | Accepted | Agents accept it unchanged; final decode reuses existing validate+repair; grounding becomes a routing concern, not an agent concern. |
| Tool-call format = JSON object with a `tool` key. | Accepted | Simplest to parse/prompt; reuses `JSONExtraction` + `JSONValue`; distinguishable from the final answer by the `tool` key. |
| Tools wired only into Generation + Reflection. | Accepted | Highest-value grounding (hypothesis creation + novelty); proves the loop before broadening (per plan Non-Goals). |
