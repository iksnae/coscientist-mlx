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
    var useRemoteJudge: Bool = false
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
