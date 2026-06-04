import AICoScientistKit
import SwiftUI

/// Trailing inspector showing a selected hypothesis's full detail: metrics, the latest peer
/// review (six dimensions + qualitative feedback), cluster, and evolution lineage. Renders the
/// pure `HypothesisDetail` projection — no logic here.
struct HypothesisInspector: View {
    let detail: HypothesisDetail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                metrics
                Text(detail.text).font(.body).textSelection(.enabled)
                if let review = detail.latestReview {
                    Divider()
                    Text("Latest review (of \(detail.reviewCount))").font(.headline)
                    scoreBars(review.scores)
                    if !review.reviewSummary.isEmpty {
                        Text(review.reviewSummary).font(.callout)
                    }
                    bullets("Strengths", review.strengths)
                    bullets("Weaknesses", review.weaknesses)
                    bullets("Suggestions", review.suggestions)
                    if !review.safetyEthicalConcerns.isEmpty {
                        Text("Safety: \(review.safetyEthicalConcerns)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if !detail.lineage.isEmpty {
                    Divider()
                    Text("Lineage").font(.headline)
                    ForEach(Array(detail.lineage.enumerated()), id: \.offset) { index, step in
                        Label(step, systemImage: index == 0 ? "leaf" : "arrow.triangle.branch")
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private var metrics: some View {
        HStack(spacing: 12) {
            Label("\(detail.eloRating)", systemImage: "trophy").foregroundStyle(.blue)
            Text(String(format: "score %.2f", detail.score)).foregroundStyle(.secondary)
            if detail.totalMatches > 0 {
                Text("\(detail.winCount)–\(detail.lossCount) · \(Int(detail.winRate))%")
                    .foregroundStyle(.secondary)
            }
            if let cluster = detail.clusterID {
                Text(cluster).padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        }
        .font(.caption.monospacedDigit())
    }

    private func scoreBars(_ scores: ReviewScores) -> some View {
        let dims: [(String, Double)] = [
            ("Soundness", scores.scientificSoundness), ("Novelty", scores.novelty),
            ("Relevance", scores.relevance), ("Testability", scores.testability),
            ("Clarity", scores.clarity), ("Impact", scores.impact),
        ]
        return VStack(alignment: .leading, spacing: 3) {
            ForEach(dims, id: \.0) { name, value in
                HStack(spacing: 6) {
                    Text(name).font(.caption2).frame(width: 78, alignment: .leading)
                    ProgressView(value: value).frame(maxWidth: 120)
                    Text(String(format: "%.2f", value))
                        .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private func bullets(_ title: String, _ items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.bold())
                ForEach(items, id: \.self) { Text("• \($0)").font(.caption) }
            }
        }
    }
}
