import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Agent tool use")
struct ToolUseTests {

    // A stub tool whose result carries a sentinel, so we can prove the result reached
    // the final decode.
    private struct StubTool: AgentTool {
        let name = "stub_search"
        let description = "Stub search tool for tests."
        var parameters: JSONSchema { .object(properties: ["query": .string()], required: ["query"]) }
        func call(_ arguments: JSONValue) async throws -> String { "STUBHIT" }
    }

    // Counts how many times it is invoked — an actor so the @Sendable loop never races.
    private actor CallCounter {
        private(set) var count = 0
        func bump() { count += 1 }
    }
    private struct CountingTool: AgentTool {
        let name = "counter"
        let description = "Counts calls."
        var parameters: JSONSchema { .object(properties: [:], required: []) }
        let counter: CallCounter
        func call(_ arguments: JSONValue) async throws -> String { await counter.bump(); return "ok" }
    }

    private let toolCall = #"{"tool":"stub_search","args":{"query":"batteries"}}"#

    @Test("Registry resolves by name and returns nil for an unknown tool")
    func registryResolves() {
        let registry = ToolRegistry([StubTool()])
        #expect(registry.resolve("stub_search")?.name == "stub_search")
        #expect(registry.resolve("missing") == nil)
        #expect(registry.all.count == 1)
    }

    @Test("Parser extracts a tool call and rejects non-tool objects / prose")
    func parserExtractsAndRejects() {
        let call = ToolCallParser.parse("Sure: \(toolCall) — running it.")
        #expect(call?.name == "stub_search")
        #expect(call?.arguments["query"]?.stringValue == "batteries")
        #expect(ToolCallParser.parse(#"{"winner":"a","rationale":"r"}"#) == nil)
        #expect(ToolCallParser.parse("no json at all") == nil)
    }

    @Test("Loop executes a tool call, feeds the result back, and grounds the final decode")
    func loopGroundsFinalDecode() async throws {
        // Loop model: emit a tool call until results are present, then stop.
        let loopModel = MockLanguageModel { _, user in
            user.contains("STUBHIT") ? "I have enough now." : self.toolCall
        }
        // Inner model: winner reflects whether the tool result reached it.
        let innerModel = MockLanguageModel { _, user in
            let winner = user.contains("STUBHIT") ? "a" : "b"
            return #"{"winner":"\#(winner)","rationale":"r"}"#
        }
        let grounded = GroundedDecoder(
            model: loopModel, tools: ToolRegistry([StubTool()]),
            inner: SchemaConstrainedDecoder(model: innerModel))
        let verdict = try await grounded.decode(
            TournamentJudgment.self, system: "s", user: "compare", config: .deterministic)
        #expect(verdict.winner == .a)  // grounded note reached the final decode
    }

    @Test("A response with no tool call falls through to the inner decode unchanged")
    func noToolCallIsIdentical() async throws {
        let innerModel = MockLanguageModel(constant: #"{"winner":"b","rationale":"r"}"#)
        let inner = SchemaConstrainedDecoder(model: innerModel)
        let plain = try await inner.decode(
            TournamentJudgment.self, system: "s", user: "u", config: .deterministic)

        let grounded = GroundedDecoder(
            model: MockLanguageModel(constant: "just thinking, no tool call"),
            tools: ToolRegistry([StubTool()]), inner: inner)
        let out = try await grounded.decode(
            TournamentJudgment.self, system: "s", user: "u", config: .deterministic)

        #expect(out.winner == plain.winner)
        #expect(out.rationale == plain.rationale)
    }

    @Test("The loop is bounded by maxToolSteps, then forces a final decode")
    func boundedBySteps() async throws {
        let counter = CallCounter()
        let grounded = GroundedDecoder(
            model: MockLanguageModel(constant: #"{"tool":"counter","args":{}}"#),
            tools: ToolRegistry([CountingTool(counter: counter)]),
            inner: SchemaConstrainedDecoder(
                model: MockLanguageModel(constant: #"{"winner":"a","rationale":"r"}"#)),
            maxToolSteps: 2)
        let verdict = try await grounded.decode(
            TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
        #expect(verdict.winner == .a)         // still produced a final answer
        #expect(await counter.count == 2)     // capped at maxToolSteps, no runaway
    }

    @Test("The observer hook reports each executed tool call")
    func observerReportsCalls() async throws {
        let box = NameBox()
        let grounded = GroundedDecoder(
            model: MockLanguageModel { _, user in user.contains("STUBHIT") ? "done" : self.toolCall },
            tools: ToolRegistry([StubTool()]),
            inner: SchemaConstrainedDecoder(
                model: MockLanguageModel(constant: #"{"winner":"a","rationale":"r"}"#)),
            onToolCall: { box.add($0.name) })
        _ = try await grounded.decode(
            TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
        #expect(box.all.contains("stub_search"))
    }

    // Synchronous, thread-safe collector — the observer hook is a non-async @Sendable closure.
    private final class NameBox: @unchecked Sendable {
        private let lock = NSLock()
        private var names: [String] = []
        func add(_ name: String) { lock.lock(); names.append(name); lock.unlock() }
        var all: [String] { lock.lock(); defer { lock.unlock() }; return names }
    }
}
