import AICoScientistKit
import Charts
import SwiftUI

/// Visualizations of a run: how Elo ratings evolve over the workflow, and the current
/// ranking of the pool. Uses Swift Charts with semantic colors so it adapts to light/dark.
struct ChartsView: View {
    let timeline: [WorkflowRunner.ProgressPoint]
    let hypotheses: [Hypothesis]

    var body: some View {
        if timeline.isEmpty {
            ContentUnavailableView(
                "No data yet", systemImage: "chart.xyaxis.line",
                description: Text("Run the workflow to chart Elo progression and the live ranking."))
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    eloProgression
                    currentRanking
                }
                .padding()
            }
        }
    }

    private var eloProgression: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Elo progression").font(.headline)
            Text("Top vs. average rating across the run")
                .font(.caption).foregroundStyle(.secondary)
            Chart(timeline) { point in
                LineMark(
                    x: .value("Step", point.step),
                    y: .value("Elo", point.topElo),
                    series: .value("Series", "Top"))
                .foregroundStyle(by: .value("Series", "Top"))
                .interpolationMethod(.monotone)

                LineMark(
                    x: .value("Step", point.step),
                    y: .value("Elo", point.avgElo),
                    series: .value("Series", "Average"))
                .foregroundStyle(by: .value("Series", "Average"))
                .interpolationMethod(.monotone)
            }
            .chartForegroundStyleScale(["Top": Color.blue, "Average": Color.secondary])
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 200)
            .accessibilityLabel("Elo progression over \(timeline.count) steps")
        }
    }

    private var currentRanking: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current ranking").font(.headline)
            Text("Hypotheses by Elo (top \(min(hypotheses.count, 12)))")
                .font(.caption).foregroundStyle(.secondary)
            Chart(Array(hypotheses.prefix(12).enumerated()), id: \.element.id) { index, h in
                BarMark(
                    x: .value("Elo", h.eloRating),
                    y: .value("Rank", "#\(index + 1)"))
                .foregroundStyle(h.similarityClusterID.map { _ in Color.teal } ?? Color.blue)
                .annotation(position: .trailing) {
                    Text("\(h.eloRating)").font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .chartXScale(domain: .automatic(includesZero: false))
            .frame(height: max(120, Double(min(hypotheses.count, 12)) * 28))
            .accessibilityLabel("Current ranking of \(hypotheses.count) hypotheses by Elo")
        }
    }
}
