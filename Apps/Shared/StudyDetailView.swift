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
    @State private var topHypothesisExpanded = false
    @State private var configExpanded = false

    /// Show the full run config when explicitly expanded, or for a fresh draft (no results yet,
    /// not running). Once a study has results or is running, collapse to a summary so the Study
    /// data (conclusion + hypotheses) leads.
    private var showFullConfig: Bool { configExpanded || (study.snapshot == nil && !live) }

    private func choiceShortName(_ choice: ModelChoice) -> String {
        switch choice {
        case .onDevice(let key): ModelCatalog.model(key: key)?.displayName ?? key
        case .hosted(let id): id
        }
    }

    private var configSummary: String {
        "\(choiceShortName(study.generator)) · \(study.hypothesesPerGeneration) hypotheses "
            + "· \(study.iterations) iterations"
    }

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
        .onChange(of: study.id) { _, _ in configExpanded = false; topHypothesisExpanded = false }
        .alert("Not enough disk", isPresented: .constant(diskError != nil), presenting: diskError) { _ in
            Button("OK") { diskError = nil }
        } message: { Text($0) }
        .sheet(item: $confirm) { confirm in downloadSheet(confirm) }
    }

    // MARK: Outcome

    /// Leads with the conclusion when a finished study has results: a synthesis headline, then the
    /// top hypothesis truncated (expandable) so it isn't a verbatim copy of the first ranked row.
    @ViewBuilder private var outcomeHeader: some View {
        if !live, let conclusion = study.snapshot?.conclusion, conclusion.hasResult,
            let top = conclusion.topHypothesis {
            VStack(alignment: .leading, spacing: Theme.space.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.color.success)
                    Text("Conclusion").font(Theme.text.headline)
                    Spacer()
                    if let elo = conclusion.topElo {
                        Text("top Elo \(elo)").font(Theme.text.caption.monospacedDigit())
                            .foregroundStyle(Theme.color.textSecondary)
                    }
                }
                // Synthesis leads (the understanding across hypotheses); falls back to the top
                // hypothesis only when there's no separate synthesis.
                Text(conclusion.synthesis.isEmpty ? top : conclusion.synthesis)
                    .font(Theme.text.title3.weight(.semibold)).textSelection(.enabled)

                if !conclusion.synthesis.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TOP HYPOTHESIS").font(Theme.text.caption2.bold()).foregroundStyle(Theme.color.textSecondary)
                        Text(top).font(Theme.text.callout).foregroundStyle(Theme.color.textSecondary)
                            .lineLimit(topHypothesisExpanded ? nil : 3).textSelection(.enabled)
                        Button(topHypothesisExpanded ? "Show less" : "Show more") {
                            withAnimation { topHypothesisExpanded.toggle() }
                        }
                        .font(Theme.text.caption).buttonStyle(.plain).foregroundStyle(Theme.color.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal).padding(.vertical, 12)
            .background(Theme.color.successBackground)
        }
    }

    /// Surfaces errors recorded during a finished run, so a failed/empty run isn't silent.
    @ViewBuilder private var issuesBanner: some View {
        if !live, let errors = study.snapshot?.errors, !errors.isEmpty {
            VStack(alignment: .leading, spacing: Theme.space.Spacing.xs) {
                Label(
                    "\(RunStatusText.count(errors.count, "issue", "issues")) during the run",
                    systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.text.subheadline.bold()).foregroundStyle(Theme.color.warning)
                ForEach(Array(errors.prefix(6).enumerated()), id: \.offset) { _, message in
                    Text(message).font(Theme.text.caption.monospaced()).foregroundStyle(Theme.color.textSecondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if errors.count > 6 {
                    Text("…and \(errors.count - 6) more").font(Theme.text.caption).foregroundStyle(Theme.color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal).padding(.vertical, Theme.space.Spacing.sm)
            .background(Theme.color.warningBackground)
        }
    }

    // MARK: Config

    private var configHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Untitled study", text: $study.title)
                .font(.title2.weight(.semibold)).textFieldStyle(.plain).disabled(live)
                .onChange(of: study.title) { _, newTitle in
                    // The title is "custom" only when non-empty and divergent from the goal-derived
                    // default; clearing it resumes goal-tracking (no more stuck "Untitled study").
                    study.titleIsCustom = StudyTitle.isCustom(editedTitle: newTitle, goal: study.goal)
                    study.updatedAt = Date(); try? context.save()
                }
            TextField("Research goal — what should the agents investigate?",
                text: $study.goal, axis: .vertical)
                .font(.callout).foregroundStyle(.secondary)
                .textFieldStyle(.plain).lineLimit(1...3).disabled(live)
                .onChange(of: study.goal) { _, newGoal in
                    // Until the user names the study, the title follows the goal's first line.
                    if !study.titleIsCustom {
                        study.title = StudyConfig.defaultTitle(forGoal: newGoal)
                    }
                }

            if showFullConfig {
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
                    Text("Models run on-device. Add a hosted provider in Settings ▸ Providers to "
                        + "use a hosted model for the generator or reviewer.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                // Collapse affordance only matters once there are results to prioritize.
                if study.snapshot != nil && !live {
                    Button { withAnimation { configExpanded = false } } label: {
                        Label("Hide configuration", systemImage: "chevron.up")
                            .font(.caption)
                    }
                    .buttonStyle(.plain).foregroundStyle(.tint)
                }
            } else {
                Button { withAnimation { configExpanded = true } } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text(configSummary).lineLimit(1).truncationMode(.tail)
                        Spacer(minLength: 6)
                        Text("Edit"); Image(systemName: "chevron.down")
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain).disabled(live)
            }

            HStack(spacing: 12) {
                runButton
                if let download = runner.downloadProgress, live {
                    ProgressView(value: download).frame(width: 120)
                    Text("\(runner.downloadingNeeded ? "Downloading" : "Loading") model — \(Int(download * 100))%")
                        .font(.caption).foregroundStyle(.secondary)
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
                RunProgressView(runner: runner)
            } else {
                Text(statusLine).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding()
        .onChange(of: study.goal) { _, _ in study.updatedAt = Date(); try? context.save() }
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

    private var statusLine: String {
        switch study.status {
        case .done:
            return RunStatusText.finished(
                hypotheses: hypotheses.count, repairs: metrics.repairAttempts,
                decodeFailures: metrics.decodeFailures)
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
        case .activity: ActivityFeedView(events: activityEvents)
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
        PlatformExport.save(suggestedName: "\(study.title.prefix(40)).\(ext)") { url in
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
