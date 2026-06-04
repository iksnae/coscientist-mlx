/// Tunables for a research workflow, mirroring the Python `AIScientistFramework` arguments.
public struct EngineConfiguration: Sendable {
    /// Number of refinement iterations after the initial round.
    public var maxIterations: Int
    /// How many hypotheses the generation phase requests.
    public var hypothesesPerGeneration: Int
    /// Reserved for parity with the reference; tournament rounds are `poolSize * 3`.
    public var tournamentSize: Int
    /// How many top hypotheses the evolution phase refines each iteration.
    public var evolutionTopK: Int

    public init(
        maxIterations: Int = 3,
        hypothesesPerGeneration: Int = 10,
        tournamentSize: Int = 8,
        evolutionTopK: Int = 3
    ) {
        self.maxIterations = maxIterations
        self.hypothesesPerGeneration = hypothesesPerGeneration
        self.tournamentSize = tournamentSize
        self.evolutionTopK = evolutionTopK
    }
}
