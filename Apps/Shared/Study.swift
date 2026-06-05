import AICoScientistKit
import Foundation
import SwiftData

enum StudyStatus: String, Codable, Sendable {
    case draft, running, done, error
}

/// A research study: a goal plus its configuration and the latest run's results. Persisted via
/// SwiftData; the run result is stored as an encoded `RunSnapshot` so the pure Kit types stay
/// free of any persistence framework.
@Model
final class Study {
    var id: UUID = UUID()
    var title: String = "New study"
    /// Whether the user has explicitly named the study. While false, the title tracks the goal's
    /// first line (so the sidebar shows real goals instead of a row of identical seed titles);
    /// once the user edits the title it stops auto-tracking. Defaulted → CloudKit-safe.
    var titleIsCustom: Bool = false
    var goal: String = ""
    var generatorKey: String = ModelCatalog.defaultGeneratorKey
    var hypothesesPerGeneration: Int = 4
    var iterations: Int = 1
    // M14: advanced run config (defaults match EngineConfiguration).
    var evolutionTopK: Int = 3      // survivors kept after each refinement round
    var tournamentRounds: Int = 3   // tournament matches per hypothesis (pool × this)
    var useRemoteJudge: Bool = false
    // M13: per-study model selection (kind + id; computed `generator`/`reviewer` below).
    var generatorChoiceKind: String = "onDevice"
    var generatorChoiceID: String = ModelCatalog.defaultGeneratorKey
    var reviewerChoiceKind: String = "onDevice"
    var reviewerChoiceID: String = ModelCatalog.defaultGeneratorKey
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var statusRaw: String = StudyStatus.draft.rawValue
    var resultData: Data?

    init(goal: String) {
        self.goal = goal
        self.title = StudyConfig.defaultTitle(forGoal: goal)
    }

    var status: StudyStatus {
        get { StudyStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    /// The portable, persistence-free configuration — the bridge to `StudyConfig` (Kit) for
    /// export/import. Reading projects the stored fields; writing applies a config back.
    var config: StudyConfig {
        get {
            StudyConfig(
                title: title, goal: goal, generator: generator, reviewer: reviewer,
                hypothesesPerGeneration: hypothesesPerGeneration, iterations: iterations,
                evolutionTopK: evolutionTopK, tournamentRounds: tournamentRounds,
                useRemoteJudge: useRemoteJudge)
        }
        set {
            title = newValue.title
            goal = newValue.goal
            generator = newValue.generator
            reviewer = newValue.reviewer
            hypothesesPerGeneration = newValue.hypothesesPerGeneration
            iterations = newValue.iterations
            evolutionTopK = newValue.evolutionTopK
            tournamentRounds = newValue.tournamentRounds
            useRemoteJudge = newValue.useRemoteJudge
        }
    }

    /// The model that generates + evolves + ranks + meta-reviews hypotheses.
    var generator: ModelChoice {
        get { ModelChoice(kind: generatorChoiceKind, id: generatorChoiceID) }
        set { (generatorChoiceKind, generatorChoiceID) = newValue.kindAndID }
    }

    /// The model that reviews + judges hypotheses (reflection + tournament).
    var reviewer: ModelChoice {
        get { ModelChoice(kind: reviewerChoiceKind, id: reviewerChoiceID) }
        set { (reviewerChoiceKind, reviewerChoiceID) = newValue.kindAndID }
    }

    /// The latest run's results, decoded on demand.
    var snapshot: RunSnapshot? {
        get { resultData.flatMap { try? JSONDecoder().decode(RunSnapshot.self, from: $0) } }
        set { resultData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }
}

/// Portable representation of a study for `.coscientist` export/import (Hybrid sharing). Carries
/// the full `StudyConfig` (title, model choices, run config) plus the latest run snapshot.
/// Decoding is tolerant: it reads the nested `config`, falling back to the legacy flat layout so
/// older `.coscientist` files still import.
struct StudyDocument: Codable {
    var config: StudyConfig
    var snapshot: RunSnapshot?

    init(_ study: Study) {
        config = study.config
        snapshot = study.snapshot
    }

    func makeStudy() -> Study {
        let study = Study(goal: config.goal)
        study.config = config
        study.snapshot = snapshot
        study.status = snapshot == nil ? .draft : .done
        return study
    }

    private enum CodingKeys: String, CodingKey { case config, snapshot }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        snapshot = try container.decodeIfPresent(RunSnapshot.self, forKey: .snapshot)
        if let nested = try container.decodeIfPresent(StudyConfig.self, forKey: .config) {
            config = nested
        } else {
            // Legacy flat document: StudyConfig's tolerant decoder reads the shared top-level keys.
            config = try StudyConfig(from: decoder)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(config, forKey: .config)
        try container.encodeIfPresent(snapshot, forKey: .snapshot)
    }
}
