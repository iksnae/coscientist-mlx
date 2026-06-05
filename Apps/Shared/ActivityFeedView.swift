import AICoScientistKit
import Charts
import SwiftUI

/// The pipeline activity feed: an Elo sparkline header plus a scrolling, auto-following event log.
/// The caller passes live runner events while running, otherwise the persisted snapshot log.
/// Extracted from `StudyDetailView` (M21) to keep that view focused.
struct ActivityFeedView: View {
    let events: [ActivityEvent]

    var body: some View {
        if events.isEmpty {
            ContentUnavailableView(
                "No activity yet", systemImage: "list.bullet.rectangle",
                description: Text(
                    "Run the study to watch the pipeline unfold; the feed is saved with the run."))
        } else {
            VStack(spacing: 0) {
                sparkHeader
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(events) { event in
                                row(event).id(event.step)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(8)
                        .animation(.default, value: events.count)
                    }
                    .onChange(of: events.count) { _, _ in
                        if let last = events.last { proxy.scrollTo(last.step, anchor: .bottom) }
                    }
                }
            }
        }
    }

    private var sparkHeader: some View {
        let points = events.compactMap { e in e.topElo.map { (e.step, $0) } }
        return HStack {
            Label("\(events.count) steps", systemImage: "list.bullet").font(.caption)
            Spacer()
            if points.count > 1 {
                Chart(points, id: \.0) { point in
                    LineMark(x: .value("step", point.0), y: .value("elo", point.1))
                        .interpolationMethod(.monotone)
                }
                .frame(width: 150, height: 28)
                .chartXAxis(.hidden).chartYAxis(.hidden)
            }
            if let pool = events.last?.poolSize {
                Text("pool \(pool)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
    }

    private func row(_ event: ActivityEvent) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon(for: event.kind))
                .foregroundStyle(.tint).frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(event.phase).font(.caption.bold())
                    if event.iteration > 0 {
                        Text("iter \(event.iteration)").font(.caption2).foregroundStyle(.secondary)
                    }
                    if event.total > 0 {
                        Text("\(event.completed)/\(event.total)")
                            .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                if !event.detail.isEmpty {
                    Text(event.detail).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let elo = event.topElo {
                Text("top \(elo)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func icon(for kind: ActivityEvent.Kind) -> String {
        switch kind {
        case .generation: "flask"
        case .reflection: "magnifyingglass"
        case .ranking: "list.number"
        case .tournament: "trophy"
        case .metaReview: "doc.text.magnifyingglass"
        case .evolution: "arrow.triangle.branch"
        case .proximity: "circle.grid.cross"
        case .tool: "wrench.and.screwdriver"
        case .other: "circle"
        }
    }
}
