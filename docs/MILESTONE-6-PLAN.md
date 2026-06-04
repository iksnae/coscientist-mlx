# Milestone 6 Plan

Date: 2026-06-04

Working name:

```txt
Agent tool-use loop + grounded Generation/Reflection
```

## Status

Ready. Promoted from `docs/MILESTONE-6-PLANNING-DRAFT.md`.

## Goal

Make agents actually *call* the research tools that already exist. PR #29
landed the `AgentTool` protocol and three tools (arXiv, PubMed, web) but
nothing invokes them. M6 adds a provider-agnostic tool-use loop in the
domain layer that conforms to `SchemaConstrainedDecoding`, and wires it
into Generation and Reflection via the existing per-role routing — so a
developer can run with `--tools` and watch new hypotheses and novelty
judgments grounded in real sources, while the default (no-tools) path is
byte-for-byte unchanged.

## Design (resolved open questions)

- **Tool-call wire format:** a single JSON object containing a `"tool"`
  key, e.g. `{"tool":"arxiv_search","args":{"query":"..."}}`, extracted
  tolerantly from model output (reusing `JSONExtraction.extractObject` +
  `JSONValue.parse`). A parsed object *with* a `tool` key is a tool call;
  any object *without* one means the model is done gathering.
- **Where the loop lives:** `Sources/AICoScientistKit/Agents/`, next to
  `AgentTool`.
- **Key insight — no agent change needed.** `GroundedDecoder` conforms to
  `SchemaConstrainedDecoding`, so `Agent.run(_:using:)` accepts it as-is.
  Grounding an agent = routing its role to a `GroundedDecoder`. The
  loop does the free-text tool gathering, then delegates the final typed
  decode to the wrapped `SchemaConstrainedDecoder` (all existing
  validate + repair machinery reused, MLX or mock alike).

## Primary Scope (Execution Order)

Order optimizes for commit-able, independently-testable wins early: the
pure parser and registry first, then the decoder that composes them, then
the wiring that needs no new types.

### Track A — Tool-use loop in the domain layer (AICoScientistKit/Agents)

1. `ToolRegistry` — holds `[name: any AgentTool]`; `resolve(_:)` returns
   the tool or nil; `all` lists them. Pure.
2. `ToolCallParser` — extract a `{"tool","args"}` object from free text;
   returns `(name, JSONValue)` or nil; tolerant of surrounding prose.
3. `GroundedDecoder: SchemaConstrainedDecoding` — wraps a `LanguageModel`,
   a `ToolRegistry`, an inner `SchemaConstrainedDecoding`, and a
   `maxToolSteps` bound. Builds a tool-aware system preamble, loops
   (generate → parse tool call → execute → append observation) to the
   bound, then delegates the final schema-constrained decode with the
   gathered notes. With zero observations, the final user prompt equals
   the original (guaranteeing identical no-tools output). An optional
   observer hook reports each tool call for transcript/activity.

### Track B — Wire Generation + Reflection (AICoScientistKit)

Add a small builder that, given a base decoder + a `ToolRegistry`,
produces a `DecoderRouting` whose `.generation` and `.reflection` roles
resolve to a `GroundedDecoder` and all other roles to the base. The
engine already consumes `DecoderRouting`, so no engine change. Tests
assert a grounded Generation/Reflection agent run consumes a tool result,
and that an ungrounded run is unchanged.

### Track C — CLI wiring (AICoScientistCLI)

A `--tools` flag that constructs the arXiv/PubMed/web tools from
`AICoScientistRemote`, builds the grounded router (Track B), and routes
the run through it. Each tool call is recorded in the existing
interaction transcript via the observer hook.

## Definition Of Done

- `ToolRegistry` resolves tools by name and returns nil for unknown names.
- `ToolCallParser` extracts a tool call from text containing a
  `{"tool","args"}` object and returns nil when none is present.
- The tool-use loop executes a scripted tool call, feeds the observation
  back, and terminates with a validated typed output (mock backend).
- A no-tool-call response falls through to the inner one-shot decode with
  identical output.
- The loop is bounded by `maxToolSteps` and forces a final decode when
  the cap is hit.
- Generation and Reflection produce grounded output when routed through
  the grounded router and unchanged output when not.
- `--tools` runs the grounded path; tool calls are recorded in the
  transcript.
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M6 tracking + closeout docs land with the final commit.

## Non-Goals

- Native function-calling APIs (Foundation Models / OpenAI tool-calls) —
  that is M8.
- Hosted per-agent model backing — that is M7.
- Wiring tools into Meta-Review, Evolution, Tournament, or Ranking.
- A tools toggle / web-search-key UI in the apps — later (M7/M9 UX).
