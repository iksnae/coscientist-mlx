import AICoScientistKit
import AppKit
import SwiftUI

/// The demo playground: enter a research goal and watch the full co-scientist workflow run
/// live and on-device — hypotheses re-ranking by Elo, clustering, granular per-step progress,
/// and metrics updating in real time. Export the finished run as JSON or Markdown.
struct PlaygroundView: View {
    @State private var runner = WorkflowRunner()

    var body: some View {
        HSplitView {
            controls.frame(minWidth: 320, maxWidth: 400)
            hypothesesList.frame(minWidth: 520)
        }
        .frame(minWidth: 920, minHeight: 600)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CoScientist").font(.largeTitle.bold())
            Text("Local AI co-scientist on Apple Silicon")
                .font(.subheadline).foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Research goal").font(.headline)
                TextField("goal", text: $runner.goal, axis: .vertical)
                    .textFieldStyle(.roundedBorder).lineLimit(2...5).disabled(runner.running)
            }
            Stepper("Hypotheses: \(runner.hypothesesPerGeneration)",
                value: $runner.hypothesesPerGeneration, in: 2...12).disabled(runner.running)
            Stepper("Iterations: \(runner.iterations)",
                value: $runner.iterations, in: 1...4).disabled(runner.running)

            HStack {
                Button {
                    Task { await runner.run() }
                } label: {
                    HStack {
                        if runner.running { ProgressView().controlSize(.small) }
                        Text(runner.running ? "Running…" : "Run workflow")
                    }
                }
                .buttonStyle(.borderedProminent).disabled(runner.running)

                Menu("Export") {
                    Button("JSON…") { exportJSON() }
                    Button("Markdown…") { exportMarkdown() }
                }
                .disabled(!runner.canExport).fixedSize()
            }

            progress
            Divider()
            metrics
            Divider()
            activityLog
        }
        .padding()
    }

    @ViewBuilder private var progress: some View {
        if !runner.phase.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(runner.phase.uppercased())
                        .font(.caption2.bold().monospaced())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.tint.opacity(0.15), in: Capsule()).foregroundStyle(.tint)
                    if !runner.detail.isEmpty {
                        Text(runner.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let fraction = runner.phaseFraction {
                    ProgressView(value: fraction)
                }
            }
        }
        Text(runner.status).font(.callout).foregroundStyle(.secondary)
    }

    private var metrics: some View {
        let m = runner.metrics
        return VStack(alignment: .leading, spacing: 3) {
            Text("Metrics").font(.headline)
            Group {
                Text("hypotheses \(m.hypothesisCount)  ·  reviews \(m.reviewsCount)")
                Text("matches \(m.tournamentsCount)  ·  evolutions \(m.evolutionsCount)")
                Text("repairs \(m.repairAttempts)  ·  decode failures \(m.decodeFailures)")
                    .foregroundStyle(m.decodeFailures > 0 ? .orange : .secondary)
            }.font(.caption.monospaced())
        }
    }

    private var activityLog: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Activity").font(.headline)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(runner.activity.enumerated()), id: \.offset) { idx, line in
                            Text(line).font(.caption2.monospaced())
                                .foregroundStyle(.secondary).id(idx)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 160)
                .onChange(of: runner.activity.count) { _, count in
                    if count > 0 { proxy.scrollTo(count - 1, anchor: .bottom) }
                }
            }
        }
    }

    private var hypothesesList: some View {
        Group {
            if runner.hypotheses.isEmpty {
                ContentUnavailableView(
                    "No hypotheses yet", systemImage: "flask",
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
                                Text(cluster).font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(.quaternary, in: Capsule())
                            }
                        }
                        Text(h.text).font(.callout)
                    }.padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Export

    private func exportJSON() {
        guard let snapshot = runner.makeSnapshot() else { return }
        save(suggestedName: "coscientist-run.json") { url in
            try RunStore.save(snapshot, to: url)
        }
    }

    private func exportMarkdown() {
        guard let snapshot = runner.makeSnapshot() else { return }
        save(suggestedName: "coscientist-run.md") { url in
            try snapshot.markdown().write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func save(suggestedName: String, write: (URL) throws -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? write(url)
    }
}
