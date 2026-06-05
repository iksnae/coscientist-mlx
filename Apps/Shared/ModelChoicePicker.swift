import AICoScientistKit
import Foundation
import SwiftUI

/// Selects a `ModelChoice` (on-device catalog model or hosted model) for a role, surfacing the
/// device-RAM compatibility + strengths research (`docs/MODELS.md`) and install state. On-device
/// models are listed compatible-first; the caption explains the current choice.
struct ModelChoicePicker: View {
    let title: String
    @Binding var choice: ModelChoice
    var store: SettingsStore

    private var deviceRAMGB: Int {
        max(1, Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824))
    }

    /// On-device generators, compatible-first then most-capable (largest) first.
    private var generators: [CatalogModel] {
        ModelCatalog.generators.sorted { a, b in
            let aFits = a.fit(deviceRAMGB: deviceRAMGB) != .insufficient
            let bFits = b.fit(deviceRAMGB: deviceRAMGB) != .insufficient
            return aFits == bFits ? a.approxSizeGB > b.approxSizeGB : aFits
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Menu {
                Section("On-device") {
                    ForEach(generators) { model in
                        Button { choice = .onDevice(model.key) } label: { Text(itemLabel(model)) }
                    }
                }
                let hosted = store.hostedModelOptions
                if !hosted.isEmpty {
                    Section("Hosted") {
                        ForEach(hosted, id: \.self) { id in
                            Button { choice = .hosted(id) } label: { Text(id) }
                        }
                    }
                }
            } label: {
                LabeledContent(title) { Text(currentTitle) }
            }
            if let caption { Text(caption).font(.caption).foregroundStyle(.secondary) }
        }
        .task { await store.ensureModelsLoaded() }
    }

    private var currentTitle: String {
        switch choice {
        case .onDevice(let key): ModelCatalog.model(key: key)?.displayName ?? key
        case .hosted(let id): "\(id) · hosted"
        }
    }

    private func itemLabel(_ model: CatalogModel) -> String {
        let mark = ModelCache.isDownloaded(model.repoID) ? "✓ " : ""
        let unfit = model.fit(deviceRAMGB: deviceRAMGB) == .insufficient
            ? "  ⚠︎ needs \(model.minRAMGB) GB" : ""
        return "\(mark)\(model.displayName) · \(model.tier) · ~\(sizeGB(model))\(unfit)"
    }

    private var caption: String? {
        switch choice {
        case .onDevice(let key):
            guard let model = ModelCatalog.model(key: key) else { return nil }
            let install = ModelCache.isDownloaded(model.repoID)
                ? "downloaded" : "downloads ~\(sizeGB(model))"
            let fit =
                switch model.fit(deviceRAMGB: deviceRAMGB) {
                case .comfortable: "fits this Mac comfortably"
                case .tight: "fits (tight on RAM)"
                case .insufficient: "may not fit (\(model.minRAMGB) GB recommended)"
                }
            return "\(model.strengths) — \(fit), \(install)."
        case .hosted(let id):
            return "Hosted model \(id) — runs via your provider; nothing downloads."
        }
    }

    private func sizeGB(_ model: CatalogModel) -> String {
        "\(String(format: "%.1f", model.approxSizeGB)) GB"
    }
}
