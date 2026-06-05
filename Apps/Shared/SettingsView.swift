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
        #if os(macOS)
            .frame(width: 580, height: 480)   // sized for the macOS Settings window
        #endif
    }
}

private struct ModelsSettings: View {
    @State private var store = SettingsStore.shared
    @State private var downloaded: [ModelCache.DownloadedModel] = []
    @State private var totalBytes: Int64 = 0

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Embeddings (on-device)") {
                Picker("Embedder", selection: $store.embedderKey) {
                    ForEach(ModelCatalog.embedders) { Text($0.displayName).tag($0.key) }
                }
                Text("Embeddings always run on-device. The Generator and Reviewer models are "
                    + "chosen per study.")
                    .font(.caption).foregroundStyle(.secondary)
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
                TextField("Base URL", text: $store.remoteBaseURL)
                SecureField("API key", text: $store.openAIKey)
                HStack {
                    defaultModelField($store)
                    Button {
                        Task { await store.refreshModels() }
                    } label: {
                        Label(store.isFetchingModels ? "Fetching…" : "Refresh",
                            systemImage: "arrow.clockwise")
                    }
                    .disabled(store.openAIKey.isEmpty || store.isFetchingModels)
                }
                if let error = store.modelsError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
                // Single string literal (not `+`-concatenated) so SwiftUI parses the markdown
                // link and makes it tappable, opening the keys page in the browser.
                Text("OpenAI-compatible. Get an API key from your OpenAI account [here](https://platform.openai.com/api-keys), then paste it above with a base URL and model — hosted models appear automatically as a study's Generator or Reviewer. The key is stored locally in app preferences.")
                    .font(.caption).foregroundStyle(.secondary)
                    .tint(.blue)
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
            TextField("Model", text: store.remoteModel)
        } else {
            Picker("Model", selection: store.remoteModel) {
                ForEach(store.wrappedValue.fetchedModels, id: \.self) { Text($0).tag($0) }
            }
        }
    }
}
