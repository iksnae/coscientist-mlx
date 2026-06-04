import AICoScientistKit
import AICoScientistMLX
import AICoScientistRemote
import ArgumentParser
import Foundation

@main
struct AICoScientistCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aicoscientist",
        abstract: "Multi-agent scientific hypothesis generation on Apple Silicon (MLX)."
    )

    @Argument(help: "The research goal to explore.")
    var goal: String = ""

    @Flag(help: "Run the full multi-agent workflow (downloads ~4.5 GB on first run).")
    var run = false

    @Flag(help: "Load the model and generate a single sample instead of the full workflow.")
    var probe = false

    @Option(help: "Refinement iterations after the initial round.")
    var iterations = 2

    @Option(help: "Hypotheses to generate initially.")
    var count = 6

    @Option(help: "Path to save the run result as JSON.")
    var save: String?

    @Option(help: "Hybrid: route reflection + tournament to a remote OpenAI-compatible model (uses OPENAI_API_KEY), keeping generation/evolution on-device.")
    var remoteJudge: String?

    @Option(name: .customLong("model"),
        help: "Local generator: a catalog key (e.g. qwen3-4b) or HF repo id. See --list-models.")
    var modelKey: String?

    @Flag(help: "List the curated model catalog and exit.")
    var listModels = false

    @Option(help: "Resume a saved run (JSON path): continue refinement, skipping generation.")
    var resumePath: String?

    mutating func run() async throws {
        if listModels {
            Self.printCatalog()
            return
        }
        guard !goal.isEmpty || resumePath != nil else {
            print("Provide a research goal (or --list-models, or --resume <path>). See --help.")
            return
        }
        print("coscientist-mlx \(BuildInfo.version)")
        print("Research goal: \(goal)\n")

        if probe {
            try await runProbe()
        } else if run {
            try await runWorkflow()
        } else {
            print("Pass --run for the full workflow, or --probe for a single sample.")
        }
    }

    private static func printCatalog() {
        func line(_ m: CatalogModel) {
            print("  \(m.key.padding(toLength: 18, withPad: " ", startingAt: 0)) "
                + "~\(String(format: "%.1f", m.approxSizeGB)) GB  \(m.repoID)")
        }
        print("Curated models (pinned to a commit). Use the key with --model.\n")
        print("Generators:"); ModelCatalog.generators.forEach(line)
        print("Embedders:"); ModelCatalog.embedders.forEach(line)
        print("\nTrusted orgs (load at 'main' with a warning): "
            + ModelCatalog.trustedOrgs.sorted().joined(separator: ", "))
    }

    private func runProbe() async throws {
        print("Loading local model (first run downloads from Hugging Face)…")
        let llm = try await MLXLanguageModel.load(modelKey ?? ModelCatalog.defaultGeneratorKey)
        let reply = try await llm.generateText(
            system: "You are a terse scientific assistant. Propose one concise, testable hypothesis.",
            user: goal,
            config: .deterministic
        )
        print("\n--- model output ---\n\(reply)")
    }

    private func runWorkflow() async throws {
        print("Loading local models (first run downloads from Hugging Face)…")
        let llm = try await MLXLanguageModel.load(modelKey ?? ModelCatalog.defaultGeneratorKey)
        let embedder = try await MLXEmbeddingModel.load()
        let decodeMetrics = DecodeMetrics()
        let localDecoder = SchemaConstrainedDecoder(model: llm, metrics: decodeMetrics)

        let router: any DecoderRouting
        if let remoteJudge {
            let remoteDecoder = SchemaConstrainedDecoder(
                model: RemoteLanguageModel(model: remoteJudge), metrics: decodeMetrics)
            router = RoleDecoderRouter(
                default: localDecoder,
                overrides: [.reflection: remoteDecoder, .tournament: remoteDecoder])
            print("Hybrid: reflection + tournament → remote \(remoteJudge); rest on-device.\n")
        } else {
            router = StaticDecoderRouter(localDecoder)
        }

        let engine = CoScientistEngine(
            router: router,
            config: .init(maxIterations: iterations, hypothesesPerGeneration: count),
            proximityAnalyzer: EmbeddingProximityAnalyzer(model: embedder),
            decodeMetrics: decodeMetrics
        )

        let result: WorkflowResult
        if let resumePath {
            let snapshot = try RunStore.load(from: URL(fileURLWithPath: resumePath))
            print("Resuming from \(resumePath) (\(snapshot.hypotheses.count) hypotheses)…\n")
            result = await engine.resume(from: snapshot, additionalIterations: iterations)
        } else {
            print("Running workflow…\n")
            result = await engine.run(researchGoal: goal)
        }

        print("--- Top hypotheses (by Elo) ---")
        for (rank, h) in result.topRankedHypotheses.enumerated() {
            print("\(rank + 1). [elo \(h.eloRating), score \(String(format: "%.2f", h.score))] \(h.text)")
        }
        print("\n--- Metrics ---")
        print("hypotheses=\(result.metrics.hypothesisCount) reviews=\(result.metrics.reviewsCount) "
            + "matches=\(result.metrics.tournamentsCount) evolutions=\(result.metrics.evolutionsCount) "
            + "repairs=\(result.metrics.repairAttempts) decodeFailures=\(result.metrics.decodeFailures)")
        print(String(format: "time=%.1fs", result.totalWorkflowTime))
        let phaseTimes = result.metrics.agentExecutionTimes
            .filter { $0.key != "total" }
            .sorted { $0.value > $1.value }
        if !phaseTimes.isEmpty {
            print("phase times: "
                + phaseTimes.map { String(format: "%@=%.1fs", $0.key, $0.value) }.joined(separator: " "))
        }
        if !result.errors.isEmpty {
            print("\n--- Errors (\(result.errors.count)) ---")
            result.errors.forEach { print("• \($0)") }
        }

        if let save {
            let url = URL(fileURLWithPath: save)
            let snapshot = RunSnapshot(researchGoal: goal, result: result)
            switch url.pathExtension.lowercased() {
            case "md": try snapshot.markdown().write(to: url, atomically: true, encoding: .utf8)
            case "csv": try snapshot.csv().write(to: url, atomically: true, encoding: .utf8)
            default: try RunStore.save(snapshot, to: url)
            }
            print("\nSaved run to \(url.path)")
        }
    }
}
