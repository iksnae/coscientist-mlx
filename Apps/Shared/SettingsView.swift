import AICoScientistKit
import AICoScientistMLX
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
    @State private var downloadingKey: String?
    @State private var downloadProgress = 0.0
    @State private var actionError: String?

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

            Section("Models (pinned, verified)") {
                ForEach(ModelCatalog.all) { model in catalogRow(model) }
                Text("Download a model here to use it offline, or delete it to reclaim disk. "
                    + "Hosted (OpenAI-compatible) models always run over the network.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if !otherDownloads.isEmpty {
                Section("Other downloads") {
                    ForEach(otherDownloads, id: \.repoID) { item in
                        HStack {
                            Text(item.repoID).font(.caption).lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Text(byteString(item.bytes)).font(.caption).foregroundStyle(.secondary)
                            Button(role: .destructive) {
                                try? ModelCache.clear(item.repoID); refresh()
                            } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless).help("Delete to reclaim disk")
                        }
                    }
                }
            }

            Section { Text("\(byteString(totalBytes)) used on disk").font(.caption).foregroundStyle(.secondary) }
        }
        .formStyle(.grouped)
        .onAppear(perform: refresh)
        .alert("Couldn’t download", isPresented: .constant(actionError != nil), presenting: actionError) { _ in
            Button("OK") { actionError = nil }
        } message: { Text($0) }
    }

    @ViewBuilder private func catalogRow(_ model: CatalogModel) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(model.displayName)
                Text(model.repoID).font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            if downloadingKey == model.key {
                ProgressView(value: downloadProgress).frame(width: 70)
                Text("\(Int(downloadProgress * 100))%")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 34)
            } else if ModelCache.isDownloaded(model.repoID) {
                Text(byteString(ModelCache.sizeBytes(model.repoID)))
                    .font(.caption).foregroundStyle(.secondary)
                Button(role: .destructive) {
                    try? ModelCache.clear(model.repoID); refresh()
                } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless).help("Delete to reclaim disk")
            } else {
                Text("~\(String(format: "%.1f", model.approxSizeGB)) GB")
                    .font(.caption).foregroundStyle(.secondary)
                Button { startDownload(model) } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .buttonStyle(.borderless).help("Download for offline use")
                .disabled(downloadingKey != nil)
            }
        }
    }

    /// Downloaded models that aren't in the curated catalog (so they can still be cleared).
    private var otherDownloads: [ModelCache.DownloadedModel] {
        downloaded.filter { d in !ModelCatalog.all.contains { $0.repoID == d.repoID } }
    }

    private func startDownload(_ model: CatalogModel) {
        if case let .insufficientDisk(needed, free) = DownloadGuard.decide(forKeyOrID: model.key) {
            actionError = "\(model.displayName) needs ~\(byteString(needed)), but only "
                + "\(byteString(free)) is free. Delete a model or free up space."
            return
        }
        downloadingKey = model.key
        downloadProgress = 0
        Task {
            do {
                try await ModelDownloader.download(model.key) { fraction in
                    Task { @MainActor in downloadProgress = fraction }
                }
            } catch {
                await MainActor.run { actionError = "\(error)" }
            }
            await MainActor.run { downloadingKey = nil; refresh() }
        }
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
