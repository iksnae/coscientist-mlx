import AICoScientistKit
import SwiftData
import SwiftUI

#if os(macOS)
    import AppKit
#endif

/// The research workspace: a sidebar of studies, a detail pane for the selected one, and
/// import/export of studies as `.coscientist` files.
struct StudiesView: View {
    @Environment(\.modelContext) private var context
    // Sort by a STABLE key (creation time), not updatedAt: title/goal edits bump updatedAt on
    // every keystroke, and sorting by it made the row re-sort to the top mid-edit — the selected
    // study jumped under the cursor. updatedAt still drives the "x ago" subtitle.
    @Query(sort: \Study.createdAt, order: .reverse) private var studies: [Study]
    @State private var selection: Study?
    @State private var runner = WorkflowRunner()
    @State private var showSettings = false
    @State private var renaming: Study?
    @State private var renameText = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(studies) { study in
                    StudyRow(study: study, running: runner.isRunning(study)).tag(study)
                        .contextMenu {
                            Button("Rename") { beginRename(study) }
                            Button("Delete", role: .destructive) { deleteStudy(study) }
                        }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Studies")
            .frame(minWidth: 220)
            .overlay {
                if studies.isEmpty {
                    ContentUnavailableView(
                        "No studies", systemImage: "tray",
                        description: Text("Create a study to start."))
                }
            }
            // Toolbar lives on the SIDEBAR list (not the split view) so New Study / Export /
            // Settings appear in the Studies column on iPad's two-column layout, not on the
            // empty detail column where they'd vanish.
            .toolbar {
                ToolbarItemGroup(placement: toolbarPlacement) {
                    Button(action: newStudy) { Label("New Study", systemImage: "plus") }
                    #if os(macOS)
                        Button(action: importStudy) {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                    #endif
                    Button { if let selection { export(selection) } }
                        label: { Label("Export", systemImage: "square.and.arrow.up") }
                        .disabled(selection == nil)
                    #if os(iOS)
                        Button { showSettings = true } label: { Label("Settings", systemImage: "gear") }
                    #endif
                }
            }
        } detail: {
            if let selection {
                StudyDetailView(study: selection, runner: runner)
            } else {
                ContentUnavailableView(
                    "No study selected", systemImage: "sidebar.left",
                    description: Text("Create a study or pick one from the sidebar."))
            }
        }
        .alert("Rename study", isPresented: .constant(renaming != nil), presenting: renaming) { study in
            TextField("Title", text: $renameText)
            Button("Cancel", role: .cancel) { renaming = nil }
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { study.title = trimmed; study.updatedAt = Date(); try? context.save() }
                renaming = nil
            }
        }
        #if os(iOS)
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
            }
        #endif
    }

    /// Sidebar toolbar placement: the top-bar trailing on iOS/iPadOS, the window toolbar on macOS.
    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
            .topBarTrailing
        #else
            .automatic
        #endif
    }

    private func newStudy() {
        // Seed an empty goal so the title tracks what the user types (the sidebar shows real
        // goals instead of a row of identical "New research goal" seeds).
        let study = Study(goal: "")
        context.insert(study)
        selection = study
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { deleteStudy(studies[index]) }
    }

    private func deleteStudy(_ study: Study) {
        if selection == study { selection = nil }
        context.delete(study)
    }

    private func beginRename(_ study: Study) {
        renameText = study.title
        renaming = study
    }

    private func export(_ study: Study) {
        PlatformExport.save(suggestedName: "\(study.title.prefix(40)).coscientist") { url in
            try JSONEncoder().encode(StudyDocument(study)).write(to: url)
        }
    }

    #if os(macOS)
        private func importStudy() {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.allowedContentTypes = []   // accept any; .coscientist is JSON
            guard panel.runModal() == .OK, let url = panel.url,
                let data = try? Data(contentsOf: url),
                let document = try? JSONDecoder().decode(StudyDocument.self, from: data)
            else { return }
            let study = document.makeStudy()
            context.insert(study)
            selection = study
        }
    #endif
}

private struct StudyRow: View {
    let study: Study
    let running: Bool

    var body: some View {
        HStack(spacing: 8) {
            statusDot
            VStack(alignment: .leading, spacing: 1) {
                Text(study.title.isEmpty ? "Untitled study" : study.title)
                    .lineLimit(1)
                Text(study.updatedAt, format: .relative(presentation: .named))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusDot: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .opacity(running ? 1 : 0.7)
    }

    private var color: Color {
        if running { return .blue }
        switch study.status {
        case .done: return .green
        case .error: return .red
        case .running: return .blue
        case .draft: return .secondary
        }
    }
}
