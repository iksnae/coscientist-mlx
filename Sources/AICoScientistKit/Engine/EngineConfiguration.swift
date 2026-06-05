/// Tunables for a research workflow, mirroring the Python `AIScientistFramework` arguments.
public struct EngineConfiguration: Sendable {
    /// Number of refinement iterations after the initial round.
    public var maxIterations: Int
    /// How many hypotheses the generation phase requests.
    public var hypothesesPerGeneration: Int
    /// Tournament matches run per hypothesis (total matches = pool size × this). Was a
    /// hardcoded `× 3` in the tournament phase.
    public var tournamentRoundsPerHypothesis: Int
    /// How many top hypotheses the evolution phase refines each iteration.
    public var evolutionTopK: Int
    /// How many top-ranked hypotheses the result surfaces (was a hardcoded `prefix(10)`).
    public var resultLimit: Int

    public init(
        maxIterations: Int = 3,
        hypothesesPerGeneration: Int = 10,
        tournamentRoundsPerHypothesis: Int = 3,
        evolutionTopK: Int = 3,
        resultLimit: Int = 10
    ) {
        self.maxIterations = maxIterations
        self.hypothesesPerGeneration = hypothesesPerGeneration
        self.tournamentRoundsPerHypothesis = tournamentRoundsPerHypothesis
        self.evolutionTopK = evolutionTopK
        self.resultLimit = resultLimit
    }
}
