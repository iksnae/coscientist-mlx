import AICoScientistKit
import Charts
import SwiftData
import SwiftUI

/// One study: edit its configuration, run it (with a disk/size guard), and view results
/// (live while running, otherwise the persisted snapshot).
struct StudyDetailView: View {
    @Bindable var study: Study
    let runner: WorkflowRunner
    @Environment(\.modelContext) private var context

    @State private var settings = SettingsStore.shared
    @State private var resultTab: ResultTab = .hypotheses
    @State private var selectedID: Hypothesis.ID?
    @State private var confirm: ConfirmDownload?
    @State private var diskError: String?

    private enum ResultTab: String, CaseIterable {
        case hypotheses = "Hypotheses", graph = "Graph", charts = "Charts", activity = "Activity"
    }
    private struct ConfirmDownload: Identifiable {
        let id = UUID()
        let items: [String]
        let free: Int64
    }

    private var live: Bool { runner.isRunning(study) }
    private var hypotheses: [Hypothesis] { live ? runner.hypotheses : (study.snapshot?.hypotheses ?? []) }
    private var metrics: ExecutionMetrics { live ? runner.metrics : (study.snapshot?.metrics ?? ExecutionMetrics()) }

    var body: some View {
        VStack(spacing: 0) {
            configHeader
            Divider()
            outcomeHeader
            issuesBanner
            Picker("View", selection: $resultTab) {
                ForEach(ResultTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden().padding(8)
            Divider()
            results
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: live) { _, isLive in if isLive { resultTab = .activity } }
        .alert("Not enough disk", isPresented: .constant(diskError != nil), presenting: diskError) { _ in
            Button("OK") { diskError = nil }
        } message: { Text($0) }
        .sheet(item: $confirm) { confirm in downloadSheet(confirm) }
    }

    // MARK: Outcome

    /// Leads with the conclusion when a finished study has results.
    @ViewBuilder private var outcomeHeader: some View {
        if !live, let conclusion = study.snapshot?.conclusion, conclusion.hasResult,
            let top = conclusion.topHypothesis {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    Text("Conclusion").font(.headline)
                    if let elo = conclusion.topElo {
                        Text("top Elo \(elo)").font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                Text(top).font(.title3.weight(.semibold)).textSelection(.enabled)
                if !conclusion.synthesis.isEmpty {
                    Text(conclusion.synthesis).font(.callout).foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal).padding(.vertical, 10)
            .background(.green.opacity(0.06))
        }
    }

    /// Surfaces errors recorded during a finished run, so a failed/empty run isn't silent.
    @ViewBuilder private var issuesBanner: some View {
        if !live, let errors = study.snapshot?.errors, !errors.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Label(
                    "\(errors.count) issue\(errors.count == 1 ? "" : "s") during the run",
                    systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.bold()).foregroundStyle(.orange)
                ForEach(Array(errors.prefix(6).enumerated()), id: \.offset) { _, message in
                    Text(message).font(.caption.monospaced()).foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if errors.count > 6 {
                    Text("…and \(errors.count - 6) more").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal).padding(.vertical, 8)
            .background(.orange.opacity(0.08))
        }
    }

    // MARK: Config

    private var configHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Research goal", text: $study.goal, axis: .vertical)
                .font(.title3).textFieldStyle(.plain).lineLimit(1...3).disabled(live)

            ModelChoicePicker(title: "Generator", choice: $study.generator, store: settings)
                .disabled(live)
            ModelChoicePicker(title: "Reviewer", choice: $study.reviewer, store: settings)
                .disabled(live)

            HStack(spacing: 16) {
                Stepper("Hypotheses: \(study.hypothesesPerGeneration)",
                    value: $study.hypothesesPerGeneration, in: 2...12).disabled(live).fixedSize()
                Stepper("Iterations: \(study.iterations)",
                    value: $study.iterations, in: 1...8).disabled(live).fixedSize()
            }

            DisclosureGroup("Advanced") {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper("Survivors per round: \(study.evolutionTopK)",
                        value: $study.evolutionTopK, in: 1...12).disabled(live).fixedSize()
                    Text("How many top hypotheses continue after each refinement round.")
                        .font(.caption).foregroundStyle(.secondary)
                    Stepper("Tournament rounds per hypothesis: \(study.tournamentRounds)",
                        value: $study.tournamentRounds, in: 1...6).disabled(live).fixedSize()
                    Text("Pairwise matches per hypothesis that set the Elo ranking "
                        + "(total matches = pool size × this).")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            if !settings.remoteReady {
                Text("Models run on-device. Add a hosted provider in Settings ▸ Providers to use "
                    + "a hosted model for the generator or reviewer.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                runButton
                if let download = runner.downloadProgress, live {
                    ProgressView(value: download).frame(width: 120)
                    Text("downloading \(Int(download * 100))%").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Menu("Export") {
                    Button("JSON…") { export("json") }
                    Button("Markdown…") { export("md") }
                    Button("CSV…") { export("csv") }
                }
                .disabled(study.snapshot == nil).fixedSize()
            }

            if live {
                liveProgress
            } else {
                Text(statusLine).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding()
        .onChange(of: study.goal) { _, _ in try? context.save() }
    }

    private var runButton: some View {
        Group {
            if live {
                Button(role: .destructive) { runner.cancel() } label: {
                    HStack { ProgressView().controlSize(.small); Text("Stop") }
                }
                .buttonStyle(.borderedProminent).tint(.red)
            } else {
                Button { runTapped() } label: { Text("Run study") }
                    .buttonStyle(.borderedProminent)
                    .disabled(study.goal.isEmpty || runner.running)
            }
        }
    }

    @ViewBuilder private var liveProgress: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !runner.phase.isEmpty {
                    Text(runner.phase.uppercased())
                        .font(.caption2.bold().monospaced())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.tint.opacity(0.15), in: Capsule()).foregroundStyle(.tint)
                }
                if !runner.detail.isEmpty {
                    Text(runner.detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            if let fraction = runner.phaseFraction { ProgressView(value: fraction) }
            Text(runner.status).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var statusLine: String {
        switch study.status {
        case .done:
            return "Done · \(hypotheses.count) hypotheses · "
                + "\(metrics.repairAttempts) repairs · \(metrics.decodeFailures) decode failures"
        case .error: return "Last run errored."
        case .running: return "Running…"
        case .draft: return "Draft. Configure and run."
        }
    }

    // MARK: Results

    @ViewBuilder private var results: some View {
        switch resultTab {
        case .hypotheses: inspectorSplit { hypothesesList }
        case .graph:
            inspectorSplit {
                GraphView(
                    phase: live ? runner.phase : "", hypotheses: hypotheses,
                    selectedID: $selectedID)
            }
        case .charts: ChartsView(timeline: live ? runner.timeline : [], hypotheses: hypotheses)
        case .activity: activityList
        }
    }

    /// The selected hypothesis projected for the inspector, if any.
    private var selectedDetail: HypothesisDetail? {
        guard let id = selectedID, let h = hypotheses.first(where: { $0.id == id }) else { return nil }
        return HypothesisDetail(h)
    }

    private var inspectorItem: Binding<HypothesisDetail?> {
        Binding(get: { selectedDetail }, set: { if $0 == nil { selectedID = nil } })
    }

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var sizeClass
        private var isCompact: Bool { sizeClass == .compact }
    #else
        private var isCompact: Bool { false }
    #endif

    /// Results content + the hypothesis inspector. On regular width (iPad/macOS) the inspector
    /// is a trailing pane; on compact width (iPhone) it's a sheet so the list stays full-width.
    @ViewBuilder private func inspectorSplit<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        if isCompact {
            content()
                .sheet(item: inspectorItem) { detail in
                    NavigationStack {
                        HypothesisInspector(detail: detail)
                            .navigationTitle("Hypothesis")
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { selectedID = nil }
                                }
                            }
                    }
                }
        } else {
            HStack(spacing: 0) {
                content()
                if let detail = selectedDetail {
                    Divider()
                    HypothesisInspector(detail: detail)
                        .frame(width: 320)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.default, value: selectedID)
        }
    }

    @ViewBuilder private var hypothesesList: some View {
        if hypotheses.isEmpty {
            ContentUnavailableView(
                "No hypotheses yet", systemImage: "flask",
                description: Text("Run the study to generate and rank hypotheses."))
        } else {
            List(selection: $selectedID) {
                ForEach(hypotheses) { h in
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
                    }
                    .padding(.vertical, 4)
                    .tag(h.id)
                }
            }
        }
    }

    /// Activity events: live from the runner while running, else the persisted snapshot log.
    private var activityEvents: [ActivityEvent] {
        live ? runner.activity : (study.snapshot?.activity ?? [])
    }

    @ViewBuilder private var activityList: some View {
        let events = activityEvents
        if events.isEmpty {
            ContentUnavailableView(
                "No activity yet", systemImage: "list.bullet.rectangle",
                description: Text("Run the study to watch the pipeline unfold; the feed is saved with the run."))
        } else {
            VStack(spacing: 0) {
                sparkHeader(events)
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(events) { event in
                                activityRow(event).id(event.step)
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

    private func sparkHeader(_ events: [ActivityEvent]) -> some View {
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

    private func activityRow(_ event: ActivityEvent) -> some View {
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

    // MARK: Run + guard

    private func runTapped() {
        var insufficient: String?
        var downloads: [String] = []
        var free: Int64 = 0
        for item in runner.downloadPlan(for: study) {
            switch item.decision {
            case .cached: break
            case let .proceed(bytes, freeBytes) where bytes > 0:
                downloads.append("\(item.name) (~\(byteString(bytes)))")
                free = freeBytes
            case .proceed: break
            case let .insufficientDisk(needed, freeBytes):
                insufficient = "\(item.name) needs ~\(byteString(needed)), but only "
                    + "\(byteString(freeBytes)) is free."
            }
        }
        if let insufficient {
            diskError = insufficient + " Free space (delete models in Settings ▸ Models) "
                + "or choose a smaller model."
            return
        }
        if downloads.isEmpty {
            runner.start(study: study, context: context)
        } else {
            confirm = ConfirmDownload(items: downloads, free: free)
        }
    }

    private func downloadSheet(_ confirm: ConfirmDownload) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Download models?").font(.headline)
            Text("This study needs to download:").font(.callout)
            ForEach(confirm.items, id: \.self) { Label($0, systemImage: "arrow.down.circle") }
            Text("\(byteString(confirm.free)) free on disk.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { self.confirm = nil }
                Button("Download & Run") {
                    self.confirm = nil
                    runner.start(study: study, context: context)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20).frame(width: 380)
    }

    // MARK: Export

    private func export(_ ext: String) {
        guard let snapshot = study.snapshot else { return }
        PlatformExport.save(suggestedName: "\(study.goal.prefix(40)).\(ext)") { url in
            switch ext {
            case "md": try snapshot.markdown().write(to: url, atomically: true, encoding: .utf8)
            case "csv": try snapshot.csv().write(to: url, atomically: true, encoding: .utf8)
            default: try RunStore.save(snapshot, to: url)
            }
        }
    }

    private func byteString(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
