import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Study config round-trip")
struct StudyConfigTests {

    private func sample() -> StudyConfig {
        StudyConfig(
            title: "Cheap catalysts for green hydrogen",
            goal: "Propose earth-abundant catalysts for water electrolysis.",
            generator: .onDevice("qwen3-8b"),
            reviewer: .hosted("gpt-4o"),
            hypothesesPerGeneration: 7,
            iterations: 4,
            evolutionTopK: 5,
            tournamentRounds: 6,
            useRemoteJudge: true)
    }

    @Test("Encode → decode preserves every field")
    func roundTrip() throws {
        let config = sample()
        let data = try JSONEncoder().encode(config)
        let back = try JSONDecoder().decode(StudyConfig.self, from: data)
        #expect(back == config)
    }

    @Test("A legacy document missing the new fields decodes with sane defaults")
    func tolerantDefaults() throws {
        // Only `goal` present — title, model choices, and run config all absent.
        let json = #"{"goal":"old study goal"}"#.data(using: .utf8)!
        let config = try JSONDecoder().decode(StudyConfig.self, from: json)
        #expect(config.goal == "old study goal")
        #expect(config.title == "old study goal")  // default title = goal's first line
        #expect(config.generator == .onDevice(ModelCatalog.defaultGeneratorKey))
        #expect(config.reviewer == .onDevice(ModelCatalog.defaultGeneratorKey))
        #expect(config.hypothesesPerGeneration == 4)
        #expect(config.iterations == 1)
        #expect(config.evolutionTopK == 3)
        #expect(config.tournamentRounds == 3)
        #expect(config.useRemoteJudge == false)
    }

    @Test("Title defaults to the goal's first line, trimmed")
    func titleFromGoal() {
        let config = StudyConfig(goal: "First line of goal\nsecond line ignored")
        #expect(config.title == "First line of goal")
    }

    @Test("Empty goal yields a generic default title")
    func emptyGoalTitle() {
        let config = StudyConfig(goal: "")
        #expect(config.title == "New study")
    }
}
