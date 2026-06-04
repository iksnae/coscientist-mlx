import AICoScientistKit
import Grape
import SwiftUI

/// Node-graph visualization of a study, via Grape's force-directed graph:
/// - Pipeline: the agent operations and how they connect, with the active phase highlighted.
/// - Artifacts: hypotheses (sized by Elo, colored by cluster) linked to their similarity clusters.
struct GraphView: View {
    let phase: String          // current live phase, or "" when not running
    let hypotheses: [Hypothesis]

    @State private var mode: Mode = .pipeline
    @State private var pipelineState = ForceDirectedGraphState()
    @State private var artifactState = ForceDirectedGraphState()

    enum Mode: String, CaseIterable { case pipeline = "Pipeline", artifacts = "Artifacts" }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Graph", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden().padding(8)
            Divider()
            switch mode {
            case .pipeline: pipeline
            case .artifacts: artifacts
            }
        }
    }

    // MARK: Pipeline (operations)

    private struct Phase: Identifiable { let id: String; let label: String }
    private struct Edge { let from: String; let to: String }

    private static let phases: [Phase] = [
        .init(id: "generation", label: "Generation"),
        .init(id: "reflection", label: "Reflection"),
        .init(id: "ranking", label: "Ranking"),
        .init(id: "tournament", label: "Tournament"),
        .init(id: "metaReview", label: "Meta-Review"),
        .init(id: "evolution", label: "Evolution"),
        .init(id: "proximity", label: "Proximity"),
    ]
    private static let edges: [Edge] = [
        .init(from: "generation", to: "reflection"),
        .init(from: "reflection", to: "ranking"),
        .init(from: "ranking", to: "tournament"),
        .init(from: "tournament", to: "metaReview"),
        .init(from: "metaReview", to: "evolution"),
        .init(from: "evolution", to: "reflection"),   // refinement loop
        .init(from: "tournament", to: "proximity"),
    ]

    private var pipeline: some View {
        ForceDirectedGraph(states: pipelineState) {
            Series(Self.phases) { p in
                NodeMark(id: p.id)
                    .symbolSize(radius: p.id == phase ? 16 : 11)
                    .foregroundStyle(p.id == phase ? Color.accentColor : Color.secondary)
                    .stroke(p.id == phase ? Color.accentColor : Color.clear, StrokeStyle(lineWidth: 2))
                    .annotation(p.label)
            }
            Series(Self.edges) { e in
                LinkMark(from: e.from, to: e.to)
            }
        } force: {
            .link()
            .manyBody()
            .center()
        }
    }

    // MARK: Artifacts (activity chain)

    private var clusterIDs: [String] {
        Array(Set(hypotheses.compactMap(\.similarityClusterID))).sorted()
    }

    @ViewBuilder private var artifacts: some View {
        if hypotheses.isEmpty {
            ContentUnavailableView(
                "No artifacts yet", systemImage: "point.3.connected.trianglepath.dotted",
                description: Text("Run the study to see hypotheses and how they cluster."))
        } else {
            ForceDirectedGraph(states: artifactState) {
                Series(hypotheses) { h in
                    NodeMark(id: h.id.uuidString)
                        .symbolSize(radius: radius(for: h.eloRating))
                        .foregroundStyle(color(for: h.similarityClusterID))
                        .annotation("\(h.eloRating)")
                }
                Series(clusterIDs) { cid in
                    NodeMark(id: "cluster:\(cid)")
                        .symbolSize(radius: 16)
                        .foregroundStyle(color(for: cid).opacity(0.4))
                        .stroke(color(for: cid), StrokeStyle(lineWidth: 1.5))
                        .annotation(cid)
                }
                Series(hypotheses.filter { $0.similarityClusterID != nil }) { h in
                    LinkMark(from: h.id.uuidString, to: "cluster:\(h.similarityClusterID ?? "")")
                }
            } force: {
                .link()
                .manyBody()
                .center()
            }
        }
    }

    private func radius(for elo: Int) -> CGFloat {
        6 + max(0, min(14, CGFloat(elo - 1180) / 12))
    }

    private static let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo, .red]

    private func color(for clusterID: String?) -> Color {
        guard let clusterID else { return .secondary }
        let index = abs(clusterID.hashValue) % Self.palette.count
        return Self.palette[index]
    }
}
