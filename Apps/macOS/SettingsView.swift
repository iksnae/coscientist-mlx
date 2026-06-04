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
                Picker("Embedder", selection: $store.embedderKey) {
                    ForEach(ModelCatalog.embedders) { Text($0.displayName).tag($0.key) }
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
            Section("Remote judge (hybrid)") {
                Toggle("Route reflection + tournament to a remote model", isOn: $store.remoteEnabled)
                TextField("Base URL", text: $store.remoteBaseURL).disabled(!store.remoteEnabled)
                TextField("Model", text: $store.remoteModel).disabled(!store.remoteEnabled)
                SecureField("API key", text: $store.openAIKey).disabled(!store.remoteEnabled)
                Text("OpenAI-compatible. Generation, evolution, and embeddings stay on-device; "
                    + "the key is stored in your Keychain.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Hugging Face") {
                SecureField("Access token (optional)", text: $store.hfToken)
                Text("Needed only for gated/private repos; stored in your Keychain. "
                    + "Sign in with Hugging Face (OAuth) is coming soon.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
