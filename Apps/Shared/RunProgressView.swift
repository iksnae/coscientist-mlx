import AICoScientistKit
import Charts
import SwiftUI

/// Live, multi-indicator run progress: a phase breadcrumb across the seven pipeline stages, the
/// refinement iteration, a radial gauge for progress within the current phase, the hypothesis
/// pool size, and an Elo trend sparkline. Replaces the single overloaded progress bar.
struct RunProgressView: View {
    let runner: WorkflowRunner

    private var currentStage: Int? { RunPipeline.stageIndex(forPhase: runner.phase) }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space.Spacing.md) {
            breadcrumb
            HStack(alignment: .center, spacing: Theme.space.Spacing.md) {
                phaseRing
                VStack(alignment: .leading, spacing: Theme.space.Spacing.sm) {
                    iterationRow
                    poolRow
                }
                Spacer(minLength: 8)
                sparkline
            }
            if !runner.status.isEmpty {
                Text(runner.status)
                    .font(Theme.text.caption)
                    .foregroundStyle(Theme.color.textSecondary)
            }
        }
        .animation(.easeOut(duration: 0.35), value: runner.phase)
        .animation(.easeOut(duration: 0.35), value: runner.completed)
    }

    // MARK: Phase breadcrumb (7 stages as a segmented strip + current label)

    private enum StageState { case done, current, upcoming }
    private func state(_ idx: Int) -> StageState {
        guard let cur = currentStage else { return .upcoming }
        return idx < cur ? .done : (idx == cur ? .current : .upcoming)
    }

    private var breadcrumb: some View {
        VStack(alignment: .leading, spacing: Theme.space.Spacing.xs) {
            HStack(spacing: Theme.space.Spacing.xs) {
                ForEach(Array(RunPipeline.stages.enumerated()), id: \.offset) { idx, _ in
                    Capsule()
                        .fill(segmentColor(state(idx)))
                        .frame(height: 5)
                }
            }
            HStack(spacing: Theme.space.Spacing.sm) {
                if let cur = currentStage {
                    Text(RunPipeline.displayName(RunPipeline.stages[cur]).uppercased())
                        .font(Theme.text.caption2.bold().monospaced())
                        .foregroundStyle(Theme.color.accent)
                    Text("stage \(cur + 1) of \(RunPipeline.stages.count)")
                        .font(Theme.text.caption2)
                        .foregroundStyle(Theme.color.textSecondary)
                } else if !runner.phase.isEmpty {
                    Text(runner.phase.uppercased())
                        .font(Theme.text.caption2.bold().monospaced())
                        .foregroundStyle(Theme.color.textSecondary)
                }
                if !runner.detail.isEmpty {
                    Text("· \(runner.detail)")
                        .font(Theme.text.caption2)
                        .foregroundStyle(Theme.color.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func segmentColor(_ s: StageState) -> Color {
        switch s {
        case .done:    Theme.color.accent.opacity(0.55)
        case .current: Theme.color.accent
        case .upcoming: Theme.color.textSecondary.opacity(0.2)
        }
    }

    // MARK: Radial gauge for the current phase

    private var phaseRing: some View {
        ZStack {
            Circle()
                .stroke(Theme.color.textSecondary.opacity(0.18), lineWidth: 5)
            Circle()
                .trim(from: 0, to: runner.phaseFraction ?? 0)
                .stroke(Theme.color.accent,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: runner.phaseFraction ?? 0)
            if runner.total > 0 {
                Text("\(runner.completed)/\(runner.total)")
                    .font(Theme.text.caption2.monospacedDigit().bold())
            } else {
                Image(systemName: "ellipsis")
                    .font(Theme.text.caption)
                    .foregroundStyle(Theme.color.textSecondary)
            }
        }
        .frame(width: 46, height: 46)
    }

    // MARK: Iteration + pool

    private var iterationRow: some View {
        VStack(alignment: .leading, spacing: Theme.space.Spacing.xs) {
            Text(iterationLabel)
                .font(Theme.text.caption.weight(.medium))
            if runner.maxIterations > 0 {
                ProgressView(value: Double(runner.iteration), total: Double(runner.maxIterations))
                    .frame(width: 130)
            }
        }
    }

    private var iterationLabel: String {
        runner.iteration == 0
            ? "Initial pass" : "Refinement \(runner.iteration) of \(runner.maxIterations)"
    }

    private var poolRow: some View {
        Label("\(runner.hypotheses.count) hypotheses", systemImage: "flask")
            .font(Theme.text.caption)
            .foregroundStyle(Theme.color.textSecondary)
    }

    // MARK: Elo sparkline

    @ViewBuilder private var sparkline: some View {
        let points = runner.timeline
        if points.count > 1 {
            VStack(alignment: .trailing, spacing: Theme.space.Spacing.xs) {
                Chart(points) { p in
                    LineMark(x: .value("step", p.step), y: .value("elo", p.topElo))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Theme.color.accent)
                }
                .frame(width: 96, height: 30)
                .chartXAxis(.hidden).chartYAxis(.hidden)
                if let top = points.last?.topElo {
                    Text("top Elo \(top)")
                        .font(Theme.text.caption2.monospacedDigit())
                        .foregroundStyle(Theme.color.textSecondary)
                }
            }
        }
    }
}
