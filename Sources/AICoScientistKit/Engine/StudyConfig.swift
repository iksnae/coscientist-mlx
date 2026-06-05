import Foundation

/// The portable, persistence-free configuration of a research study: everything needed to
/// reconstruct a study's setup independent of SwiftData or any UI framework. The app's
/// `Study` (`@Model`) and `StudyDocument` (`.coscientist` export) both map to and from this
/// pure value, so the field set + its `Codable` shape can be unit-tested in the Kit.
///
/// Decoding is tolerant: a document written before a field existed decodes with that field's
/// default, so older `.coscientist` files (and migrated stores) keep importing.
public struct StudyConfig: Sendable, Equatable, Codable {
    public var title: String
    public var goal: String
    /// The model that generates + evolves + ranks + meta-reviews hypotheses.
    public var generator: ModelChoice
    /// The model that judges hypotheses (reflection + tournament).
    public var reviewer: ModelChoice
    public var hypothesesPerGeneration: Int
    public var iterations: Int
    /// Survivors kept after each refinement round.
    public var evolutionTopK: Int
    /// Tournament matches per hypothesis (pool size × this).
    public var tournamentRounds: Int
    public var useRemoteJudge: Bool

    /// Defaults mirror the app's `Study` model + `EngineConfiguration`.
    public static let defaultChoice = ModelChoice.onDevice(ModelCatalog.defaultGeneratorKey)

    public init(
        title: String? = nil,
        goal: String,
        generator: ModelChoice = StudyConfig.defaultChoice,
        reviewer: ModelChoice = StudyConfig.defaultChoice,
        hypothesesPerGeneration: Int = 4,
        iterations: Int = 1,
        evolutionTopK: Int = 3,
        tournamentRounds: Int = 3,
        useRemoteJudge: Bool = false
    ) {
        self.title = title ?? StudyConfig.defaultTitle(forGoal: goal)
        self.goal = goal
        self.generator = generator
        self.reviewer = reviewer
        self.hypothesesPerGeneration = hypothesesPerGeneration
        self.iterations = iterations
        self.evolutionTopK = evolutionTopK
        self.tournamentRounds = tournamentRounds
        self.useRemoteJudge = useRemoteJudge
    }

    /// A study title derived from the goal's first non-empty line, trimmed; `"New study"` when
    /// the goal is empty. Used on creation; the title is independent of the goal thereafter.
    public static func defaultTitle(forGoal goal: String) -> String {
        let firstLine = goal.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "New study" : trimmed
    }

    private enum CodingKeys: String, CodingKey {
        case title, goal, generator, reviewer
        case hypothesesPerGeneration, iterations, evolutionTopK, tournamentRounds, useRemoteJudge
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let goal = try c.decodeIfPresent(String.self, forKey: .goal) ?? ""
        self.goal = goal
        self.title = try c.decodeIfPresent(String.self, forKey: .title)
            ?? StudyConfig.defaultTitle(forGoal: goal)
        self.generator = try c.decodeIfPresent(ModelChoice.self, forKey: .generator)
            ?? StudyConfig.defaultChoice
        self.reviewer = try c.decodeIfPresent(ModelChoice.self, forKey: .reviewer)
            ?? StudyConfig.defaultChoice
        self.hypothesesPerGeneration =
            try c.decodeIfPresent(Int.self, forKey: .hypothesesPerGeneration) ?? 4
        self.iterations = try c.decodeIfPresent(Int.self, forKey: .iterations) ?? 1
        self.evolutionTopK = try c.decodeIfPresent(Int.self, forKey: .evolutionTopK) ?? 3
        self.tournamentRounds = try c.decodeIfPresent(Int.self, forKey: .tournamentRounds) ?? 3
        self.useRemoteJudge = try c.decodeIfPresent(Bool.self, forKey: .useRemoteJudge) ?? false
    }
}
