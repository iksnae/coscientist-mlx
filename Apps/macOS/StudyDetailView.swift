import AICoScientistKit
import AppKit
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
            Picker("View", selection: $resultTab) {
                ForEach(ResultTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden().padding(8)
            Divider()
            results
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .alert("Not enough disk", isPresented: .constant(diskError != nil), presenting: diskError) { _ in
            Button("OK") { diskError = nil }
        } message: { Text($0) }
        .sheet(item: $confirm) { confirm in downloadSheet(confirm) }
    }

    // MARK: Config

    private var configHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Research goal", text: $study.goal, axis: .vertical)
                .font(.title3).textFieldStyle(.plain).lineLimit(1...3).disabled(live)

            HStack(spacing: 16) {
                Picker("Model", selection: $study.generatorKey) {
                    ForEach(ModelCatalog.generators) { Text($0.displayName).tag($0.key) }
                }
                .frame(maxWidth: 280).disabled(live)
                Stepper("Hypotheses: \(study.hypothesesPerGeneration)",
                    value: $study.hypothesesPerGeneration, in: 2...12).disabled(live).fixedSize()
                Stepper("Iterations: \(study.iterations)",
                    value: $study.iterations, in: 1...4).disabled(live).fixedSize()
            }

            Toggle("Use remote judge (hybrid)", isOn: $study.useRemoteJudge)
                .disabled(live || !settings.remoteReady)
            if !settings.remoteReady {
                Text("Configure a remote provider in Settings ▸ Providers to enable hybrid.")
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

    /// Main results content beside a trailing hypothesis inspector when something is selected.
    @ViewBuilder private func inspectorSplit<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
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

    @ViewBuilder private var activityList: some View {
        if !live {
            ContentUnavailableView(
                "Activity is live only", systemImage: "list.bullet.rectangle",
                description: Text("The step-by-step log appears while a study is running."))
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(runner.activity.enumerated()), id: \.offset) { index, line in
                            Text(line).font(.caption2.monospaced())
                                .foregroundStyle(.secondary).id(index)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(8)
                }
                .onChange(of: runner.activity.count) { _, count in
                    if count > 0 { proxy.scrollTo(count - 1, anchor: .bottom) }
                }
            }
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
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(study.goal.prefix(40)).\(ext)"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        switch ext {
        case "md": try? snapshot.markdown().write(to: url, atomically: true, encoding: .utf8)
        case "csv": try? snapshot.csv().write(to: url, atomically: true, encoding: .utf8)
        default: try? RunStore.save(snapshot, to: url)
        }
    }

    private func byteString(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
