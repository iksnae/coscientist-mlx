# Milestone 6 Closeout

Date: 2026-06-04

Milestone:

```txt
Agent tool-use loop + grounded Generation/Reflection
```

## Status

Complete.

## Delivered

### Track A — Tool-use loop (AICoScientistKit/Agents)

- `ToolRegistry` (`Sources/AICoScientistKit/Agents/ToolRegistry.swift`):
  name-indexed `AgentTool` set; `resolve(_:)`, `all`, `isEmpty`.
- `ToolCall` + `ToolCallParser`: parse a `{"tool","args"}` object from
  free-text output, reusing `JSONExtraction` + `JSONValue`; an object
  without a `tool` key (e.g. a final schema answer) is not a tool call.
- `GroundedDecoder` (`GroundedDecoder.swift`): conforms to
  `SchemaConstrainedDecoding`. Runs a bounded ReAct loop (generate →
  parse tool call → execute → feed observation back) up to `maxToolSteps`,
  then **delegates the final validated decode to a wrapped decoder**.
  Zero tool calls ⇒ the final prompt equals the original, so output is
  identical to the inner decoder. Optional `onToolCall` observer hook.

### Track B — Grounded routing (AICoScientistKit/Agents)

- `GroundedDecoder.router(base:model:tools:roles:…)`
  (`GroundedRouter.swift`): builds a `DecoderRouting` that grounds the
  generation + reflection roles and routes all others to the base. Empty
  registry ⇒ `StaticDecoderRouter(base)`. No engine or agent change —
  the engine already consumes `DecoderRouting`, and `Agent.run` already
  accepts any `SchemaConstrainedDecoding`. (This was the key design win:
  grounding is a routing concern, not an agent rewrite.)

### Track C — CLI wiring (AICoScientistCLI)

- `--tools` flag: builds a research registry (arXiv + PubMed free; web
  search added when `TAVILY_API_KEY` is set) and wraps the generation +
  reflection decoders in `GroundedDecoder`. Composes with
  `--remote-judge` (reflection grounds over the remote judge). Tool calls
  print to the run output via the observer hook.

Not in scope despite being adjacent: native function-calling (M8),
hosted per-agent backing (M7), tools wired into Meta-Review / Evolution /
Tournament / Ranking, and any app-side tools UI.

## Validation

```txt
swift build                  # clean on Apple Silicon
swift test                   # 116 tests / 24 suites green (+9 vs 107/22)
git grep "import MLX" -- '*.swift'   # only AICoScientistMLX + Package.swift manifest
git diff --check             # whitespace clean
swift run aicoscientist --help       # --tools listed and documented
```

Real-model grounded runs (`--tools --run`, which download models and hit
arXiv/PubMed) are an opt-in manual/integration step, not part of the
default `swift test` path.

## Retrospective

What worked:

- Conforming `GroundedDecoder` to `SchemaConstrainedDecoding` collapsed
  Tracks B and C: agents and the engine needed zero changes, and the
  final structured decode reused all existing validate + repair logic.
- The "zero tool calls ⇒ identical output" invariant made the no-tools
  path provably unchanged, with a direct test asserting it.
- Small, pure components (registry, parser, decoder) were each testable
  in isolation with the mock backend — fast TDD, no GPU.

What to improve:

- The CLI records tool calls by printing, not into the `Transcript`
  actor — fine for visibility, but a structured record would let the apps
  surface tool calls in the activity log / graph (M9 territory).
- Tool-call reliability on small local models is unverified here (mock
  only); the real test is a live `--tools --run`, which M7 (hosted
  backing) is designed to de-risk.

Carry forward (M7 candidates):

- Hosted per-agent model backing — make the tool-use loop reliable by
  routing tool-using roles to a capable hosted model (M7, drafted).
- Structured tool-call recording into `Transcript` so the apps can
  display tool calls (feeds M9 graph/inspector).
- Broaden grounding to Meta-Review once the loop proves out live.
