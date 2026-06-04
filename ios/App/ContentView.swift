import AICoScientistKit
import AICoScientistMLX
import Foundation
import SwiftUI

/// Minimal on-device validation spike: load a small local model, run a single generation,
/// and report telemetry (latency, approx tok/s, thermal state, free memory) — empirically
/// testing the three documented iOS unknowns: does MLX run, RAM headroom, and thermals.
struct ContentView: View {
    @State private var goal = "Improve lithium-ion battery energy density"
    @State private var status = "Idle"
    @State private var output = ""
    @State private var running = false

    private let modelId = "mlx-community/Qwen3-1.7B-4bit"

    var body: some View {
        NavigationStack {
            Form {
                Section("Research goal") {
                    TextField("goal", text: $goal, axis: .vertical)
                }
                Section {
                    Button(running ? "Running…" : "Run probe") {
                        Task { await run() }
                    }
                    .disabled(running)
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if !output.isEmpty {
                    Section("Hypothesis") {
                        Text(output).font(.callout)
                    }
                }
                Section("Device") {
                    LabeledContent("Model", value: modelId)
                    LabeledContent("Free memory", value: "\(availableMemoryMB()) MB")
                    LabeledContent("Thermal", value: thermalLabel())
                }
            }
            .navigationTitle("CoScientist")
        }
    }

    @MainActor
    private func run() async {
        running = true
        output = ""
        status = "Loading \(modelId)…"
        let memBefore = availableMemoryMB()
        MLXRuntime.setGPUCacheLimit(bytes: 20 * 1024 * 1024)

        do {
            let model = try await MLXLanguageModel.load(modelId: modelId)
            status = "Generating…"
            let start = Date()
            let reply = try await model.generateText(
                system: "You are a terse scientific assistant. Propose one concise, testable hypothesis.",
                user: goal,
                config: .deterministic
            )
            let elapsed = Date().timeIntervalSince(start)
            let memAfter = availableMemoryMB()
            let approxTokens = max(1, reply.count / 4)

            output = reply
            status = String(
                format: "OK · %.1fs · ~%.0f tok/s · thermal %@ · free %d→%d MB",
                elapsed, Double(approxTokens) / max(elapsed, 0.001),
                thermalLabel(), memBefore, memAfter
            )
        } catch {
            status = "Error: \(error)"
        }
        running = false
    }

    private func availableMemoryMB() -> Int {
        Int(os_proc_available_memory()) / (1024 * 1024)
    }

    private func thermalLabel() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}
