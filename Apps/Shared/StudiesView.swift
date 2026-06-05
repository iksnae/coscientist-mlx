import AICoScientistKit
import AppKit
import SwiftData
import SwiftUI

/// The research workspace: a sidebar of studies, a detail pane for the selected one, and
/// import/export of studies as `.coscientist` files.
struct StudiesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Study.updatedAt, order: .reverse) private var studies: [Study]
    @State private var selection: Study?
    @State private var runner = WorkflowRunner()

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(studies) { study in
                    StudyRow(study: study, running: runner.isRunning(study)).tag(study)
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
        } detail: {
            if let selection {
                StudyDetailView(study: selection, runner: runner)
            } else {
                ContentUnavailableView(
                    "No study selected", systemImage: "sidebar.left",
                    description: Text("Create a study or pick one from the sidebar."))
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: newStudy) { Label("New Study", systemImage: "plus") }
                Button(action: importStudy) { Label("Import", systemImage: "square.and.arrow.down") }
                Button { if let selection { export(selection) } }
                    label: { Label("Export", systemImage: "square.and.arrow.up") }
                    .disabled(selection == nil)
            }
        }
    }

    private func newStudy() {
        let study = Study(goal: "New research goal")
        context.insert(study)
        selection = study
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let study = studies[index]
            if selection == study { selection = nil }
            context.delete(study)
        }
    }

    private func export(_ study: Study) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(study.goal.prefix(40)).coscientist"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let data = try? JSONEncoder().encode(StudyDocument(study))
        try? data?.write(to: url)
    }

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
}

private struct StudyRow: View {
    let study: Study
    let running: Bool

    var body: some View {
        HStack(spacing: 8) {
            statusDot
            VStack(alignment: .leading, spacing: 1) {
                Text(study.goal.isEmpty ? "Untitled study" : study.goal)
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
