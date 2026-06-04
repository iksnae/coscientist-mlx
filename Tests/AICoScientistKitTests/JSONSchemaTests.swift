import Testing
@testable import AICoScientistKit

@Suite("JSON schema")
struct JSONSchemaTests {

    let judgment = TournamentJudgment.jsonSchema

    @Test("Renders a deterministic, prompt-friendly shape")
    func rendering() {
        // Fields sorted for determinism; enum and required-ness surfaced.
        #expect(judgment.rendered() == #"{"rationale": string, "winner": string(one of: a|b)}"#)
    }

    @Test("Accepts a valid value")
    func validPasses() throws {
        let v = try JSONValue.parse(#"{"winner":"a","rationale":"clear"}"#)
        #expect(judgment.validate(v).isEmpty)
    }

    @Test("Flags a missing required field")
    func missingRequired() throws {
        let v = try JSONValue.parse(#"{"rationale":"clear"}"#)
        let errors = judgment.validate(v)
        #expect(errors.contains { $0.contains("winner") && $0.contains("required") })
    }

    @Test("Flags an out-of-enum value (which plain decoding might mis-handle)")
    func enumViolation() throws {
        let v = try JSONValue.parse(#"{"winner":"c","rationale":"x"}"#)
        #expect(judgment.validate(v).contains { $0.contains("winner") })
    }

    @Test("Flags a wrong scalar type")
    func wrongType() throws {
        let v = try JSONValue.parse(#"{"winner":"a","rationale":42}"#)
        #expect(judgment.validate(v).contains { $0.contains("rationale") })
    }

    @Test("Integer schema rejects non-integral numbers")
    func integerCheck() throws {
        let schema = JSONSchema.object(properties: ["n": .integer], required: ["n"])
        #expect(schema.validate(try JSONValue.parse(#"{"n":3}"#)).isEmpty)
        #expect(!schema.validate(try JSONValue.parse(#"{"n":3.5}"#)).isEmpty)
    }

    @Test("Nested object schema (ReviewScores inside HypothesisReview) validates")
    func nestedSchema() throws {
        let valid = try JSONValue.parse(#"""
        {"scores":{"scientificSoundness":0.8,"novelty":0.7,"testability":0.9,"impact":0.6},
         "reviewSummary":"solid","strengths":["a"],"weaknesses":[],"suggestions":[]}
        """#)
        #expect(HypothesisReview.jsonSchema.validate(valid).isEmpty)

        let badNested = try JSONValue.parse(#"{"scores":{"novelty":0.7},"reviewSummary":"x"}"#)
        #expect(HypothesisReview.jsonSchema.validate(badNested).contains { $0.contains("scientificSoundness") })
    }
}
