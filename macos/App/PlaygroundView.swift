import AICoScientistKit
import SwiftUI

/// The demo playground: enter a research goal and watch the full co-scientist workflow run
/// live and on-device — hypotheses re-ranking by Elo, clustering, and metrics updating per phase.
struct PlaygroundView: View {
    @State private var runner = WorkflowRunner()

    var body: some View {
        HSplitView {
            controls
                .frame(minWidth: 300, maxWidth: 360)
            hypothesesList
                .frame(minWidth: 520)
        }
        .frame(minWidth: 880, minHeight: 560)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CoScientist").font(.largeTitle.bold())
            Text("Local AI co-scientist on Apple Silicon")
                .font(.subheadline).foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Research goal").font(.headline)
                TextField("goal", text: $runner.goal, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...5)
                    .disabled(runner.running)
            }

            Stepper("Hypotheses: \(runner.hypothesesPerGeneration)",
                value: $runner.hypothesesPerGeneration, in: 2...12)
                .disabled(runner.running)
            Stepper("Iterations: \(runner.iterations)",
                value: $runner.iterations, in: 1...4)
                .disabled(runner.running)

            Button {
                Task { await runner.run() }
            } label: {
                HStack {
                    if runner.running { ProgressView().controlSize(.small) }
                    Text(runner.running ? "Running…" : "Run workflow")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(runner.running)

            if !runner.phase.isEmpty {
                phaseBadge
            }
            Text(runner.status).font(.callout).foregroundStyle(.secondary)

            Divider()
            metrics
            Spacer()
        }
        .padding()
    }

    private var phaseBadge: some View {
        Text(runner.phase.uppercased())
            .font(.caption2.bold().monospaced())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(.tint.opacity(0.15), in: Capsule())
            .foregroundStyle(.tint)
    }

    private var metrics: some View {
        let m = runner.metrics
        return VStack(alignment: .leading, spacing: 4) {
            Text("Metrics").font(.headline)
            Group {
                Text("hypotheses \(m.hypothesisCount)  ·  reviews \(m.reviewsCount)")
                Text("matches \(m.tournamentsCount)  ·  evolutions \(m.evolutionsCount)")
                Text("repairs \(m.repairAttempts)  ·  decode failures \(m.decodeFailures)")
                    .foregroundStyle(m.decodeFailures > 0 ? .orange : .secondary)
            }
            .font(.caption.monospaced())
            if !runner.errors.isEmpty {
                Text("\(runner.errors.count) phase error(s)")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private var hypothesesList: some View {
        Group {
            if runner.hypotheses.isEmpty {
                ContentUnavailableView(
                    "No hypotheses yet",
                    systemImage: "flask",
                    description: Text("Enter a goal and run the workflow to watch hypotheses evolve."))
            } else {
                List(runner.hypotheses) { h in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Label("\(h.eloRating)", systemImage: "trophy")
                                .font(.caption.monospacedDigit()).foregroundStyle(.blue)
                            Text(String(format: "score %.2f", h.score))
                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            if h.totalMatches > 0 {
                                Text("\(Int(h.winRate))% win").font(.caption2).foregroundStyle(.secondary)
                            }
                            if let cluster = h.similarityClusterID {
                                Text(cluster)
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(.quaternary, in: Capsule())
                            }
                        }
                        Text(h.text).font(.callout)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
