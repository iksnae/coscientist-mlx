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
    var goal: String = ""
    var generatorKey: String = ModelCatalog.defaultGeneratorKey
    var hypothesesPerGeneration: Int = 4
    var iterations: Int = 1
    // M14: advanced run config (defaults match EngineConfiguration).
    var evolutionTopK: Int = 3      // survivors kept after each refinement round
    var tournamentSize: Int = 8     // hypotheses entered into the ranking tournament
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
        self.title = goal.isEmpty ? "New study" : goal
    }

    var status: StudyStatus {
        get { StudyStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
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

/// Portable representation of a study for `.coscientist` export/import (Hybrid sharing).
struct StudyDocument: Codable {
    var goal: String
    var generatorKey: String
    var hypothesesPerGeneration: Int
    var iterations: Int
    var useRemoteJudge: Bool
    var snapshot: RunSnapshot?

    init(_ study: Study) {
        goal = study.goal
        generatorKey = study.generatorKey
        hypothesesPerGeneration = study.hypothesesPerGeneration
        iterations = study.iterations
        useRemoteJudge = study.useRemoteJudge
        snapshot = study.snapshot
    }

    func makeStudy() -> Study {
        let study = Study(goal: goal)
        study.generatorKey = generatorKey
        study.hypothesesPerGeneration = hypothesesPerGeneration
        study.iterations = iterations
        study.useRemoteJudge = useRemoteJudge
        study.snapshot = snapshot
        study.status = snapshot == nil ? .draft : .done
        return study
    }
}
