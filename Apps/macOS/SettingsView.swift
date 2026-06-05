import AICoScientistKit
import Foundation
import SwiftUI

/// The dedicated Settings window (⌘,): configure providers and manage models.
struct SettingsView: View {
    var body: some View {
        TabView {
            ModelsSettings().tabItem { Label("Models", systemImage: "cube.box") }
            ProvidersSettings().tabItem { Label("Providers", systemImage: "network") }
        }
        .frame(width: 580, height: 480)
    }
}

private struct ModelsSettings: View {
    @State private var store = SettingsStore.shared
    @State private var downloaded: [ModelCache.DownloadedModel] = []
    @State private var totalBytes: Int64 = 0

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Defaults") {
                Picker("Generator", selection: $store.generatorKey) {
                    ForEach(ModelCatalog.generators) { Text($0.displayName).tag($0.key) }
                }
                .disabled(store.backend == .foundation)
                Picker("Embedder", selection: $store.embedderKey) {
                    ForEach(ModelCatalog.embedders) { Text($0.displayName).tag($0.key) }
                }
            }

            Section("Inference backend") {
                Picker("Generator backend", selection: $store.backend) {
                    Text("MLX (open models)").tag(InferenceBackend.mlx)
                    Text("Apple Foundation Models").tag(InferenceBackend.foundation)
                }
                .pickerStyle(.radioGroup)
                if store.backend == .foundation && !store.foundationAvailable {
                    Text("Apple Foundation Models isn't available on this device "
                        + "(needs Apple Intelligence on macOS 26+). MLX is used until then.")
                        .font(.caption).foregroundStyle(.orange)
                } else if store.backend == .foundation {
                    Text("Generation runs on Apple's on-device model; embeddings stay on MLX.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Catalog (pinned, verified)") {
                ForEach(ModelCatalog.all) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(model.displayName)
                            Text(model.repoID).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if ModelCache.isDownloaded(model.repoID) {
                            Label(byteString(ModelCache.sizeBytes(model.repoID)),
                                systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green).font(.caption)
                        } else {
                            Text("~\(String(format: "%.1f", model.approxSizeGB)) GB")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Downloaded — \(byteString(totalBytes)) total") {
                if downloaded.isEmpty {
                    Text("No models downloaded yet.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(downloaded, id: \.repoID) { item in
                        HStack {
                            Text(item.repoID).font(.caption).lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Text(byteString(item.bytes)).font(.caption).foregroundStyle(.secondary)
                            Button(role: .destructive) {
                                try? ModelCache.clear(item.repoID)
                                refresh()
                            } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless).help("Delete to reclaim disk")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        downloaded = ModelCache.downloaded()
        totalBytes = ModelCache.totalBytes()
    }

    private func byteString(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private struct ProvidersSettings: View {
    @State private var store = SettingsStore.shared

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Hosted provider") {
                Toggle("Enable hosted models", isOn: $store.remoteEnabled)
                TextField("Base URL", text: $store.remoteBaseURL).disabled(!store.remoteEnabled)
                SecureField("API key", text: $store.openAIKey).disabled(!store.remoteEnabled)
                HStack {
                    defaultModelField($store)
                    Button {
                        Task { await store.refreshModels() }
                    } label: {
                        Label(store.isFetchingModels ? "Fetching…" : "Refresh",
                            systemImage: "arrow.clockwise")
                    }
                    .disabled(!store.remoteEnabled || store.isFetchingModels)
                }
                if let error = store.modelsError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
                Text("OpenAI-compatible. Generation, evolution, and embeddings stay on-device "
                    + "unless you back those agents below; the key is stored locally in app preferences.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Per-agent backing") {
                HStack {
                    Button("All local") { store.applyPreset(.allLocal) }
                    Button("Hosted judge") { store.applyPreset(.hostedJudge) }
                    Button("Hosted all") { store.applyPreset(.hostedAll) }
                }
                .disabled(!store.remoteEnabled)
                DisclosureGroup("Advanced — assign each agent") {
                    ForEach(AgentRole.allCases, id: \.self) { role in
                        Picker(role.rawValue, selection: backendBinding(role, store)) {
                            Text("Local").tag("")
                            ForEach(modelChoices, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                .disabled(!store.remoteEnabled)
                Text("“Local” keeps an agent on the on-device model. Hosted backing makes "
                    + "tool-use (--tools) more reliable for that agent.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Hugging Face") {
                SecureField("Access token (optional)", text: $store.hfToken)
                Text("Needed only for gated/private repos; stored locally in app preferences. "
                    + "Sign in with Hugging Face (OAuth) is coming soon.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    /// The default remote model — a picker over discovered models, or free text before a fetch.
    @ViewBuilder private func defaultModelField(_ store: Bindable<SettingsStore>) -> some View {
        if store.wrappedValue.fetchedModels.isEmpty {
            TextField("Model", text: store.remoteModel).disabled(!store.wrappedValue.remoteEnabled)
        } else {
            Picker("Model", selection: store.remoteModel) {
                ForEach(store.wrappedValue.fetchedModels, id: \.self) { Text($0).tag($0) }
            }
            .disabled(!store.wrappedValue.remoteEnabled)
        }
    }

    /// Model ids offered in the per-agent pickers: discovered list, falling back to the default
    /// model, always including any already-assigned ids so a selection is never dropped.
    private var modelChoices: [String] {
        var ids = store.fetchedModels
        if ids.isEmpty, !store.remoteModel.isEmpty { ids = [store.remoteModel] }
        for id in store.agentModels.values where !ids.contains(id) { ids.append(id) }
        return ids
    }

    private func backendBinding(_ role: AgentRole, _ store: SettingsStore) -> Binding<String> {
        Binding(
            get: { store.agentModels[role.rawValue] ?? "" },
            set: { store.assign(role, to: $0.isEmpty ? nil : $0) })
    }
}
