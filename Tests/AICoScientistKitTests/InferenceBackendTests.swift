import Testing
@testable import AICoScientistKit

@Suite("Inference backend")
struct InferenceBackendTests {

    @Test("foundation resolves only when available; mlx is the local-first fallback")
    func resolve() {
        #expect(InferenceBackend.resolve(requested: .mlx, foundationAvailable: true) == .mlx)
        #expect(InferenceBackend.resolve(requested: .mlx, foundationAvailable: false) == .mlx)
        #expect(InferenceBackend.resolve(requested: .foundation, foundationAvailable: true) == .foundation)
        #expect(InferenceBackend.resolve(requested: .foundation, foundationAvailable: false) == .mlx)
    }

    @Test("backend is round-trippable by raw value (for flags / persistence)")
    func rawValues() {
        #expect(InferenceBackend(rawValue: "mlx") == .mlx)
        #expect(InferenceBackend(rawValue: "foundation") == .foundation)
        #expect(InferenceBackend.allCases.count == 2)
    }
}
