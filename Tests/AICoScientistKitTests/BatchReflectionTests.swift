import Testing
@testable import AICoScientistKit

@Suite("Batched reflection")
struct BatchReflectionTests {

    private let twoReviews = #"""
        {"reviews":[
          {"scores":{"scientificSoundness":0.8,"novelty":0.7,"relevance":0.75,"testability":0.9,"clarity":0.8,"impact":0.6},
           "reviewSummary":"r1","safetyEthicalConcerns":"None identified","strengths":[],"weaknesses":[],"suggestions":[]},
          {"scores":{"scientificSoundness":0.6,"novelty":0.6,"relevance":0.6,"testability":0.6,"clarity":0.6,"impact":0.6},
           "reviewSummary":"r2","safetyEthicalConcerns":"None identified","strengths":[],"weaknesses":[],"suggestions":[]}
        ]}
        """#

    @Test("Reviews the whole pool in one decode, in order")
    func batchReviews() async throws {
        let out = try await BatchReflectionAgent().run(
            .init(researchGoal: "g", hypotheses: ["H1", "H2"]),
            using: SchemaConstrainedDecoder(model: MockLanguageModel(constant: twoReviews)))
        #expect(out.reviews.count == 2)
        #expect(out.reviews.first?.reviewSummary == "r1")
        #expect(out.reviews.last?.reviewSummary == "r2")
        #expect((out.reviews.first?.scores.overall ?? 0) > 0)
    }

    @Test("Prompt includes the goal and every hypothesis in order")
    func promptListsAll() {
        let prompt = BatchReflectionAgent().userPrompt(
            for: .init(researchGoal: "battery goal", hypotheses: ["Alpha", "Beta"]))
        #expect(prompt.contains("battery goal"))
        #expect(prompt.contains("Alpha"))
        #expect(prompt.contains("Beta"))
    }

    @Test("BatchReviews schema is an object with a required reviews array")
    func schemaShape() {
        let violations = BatchReviews.jsonSchema.validate(
            try! JSONValue.parse(twoReviews))
        #expect(violations.isEmpty)
    }
}
