import Testing
@testable import AICoScientistFoundationModels

@Suite("Foundation Models backend")
struct FoundationModelsBackendTests {

    // Device-independent: whatever `isAvailable` reports on this machine, `makeModel()` must
    // agree. (No assertion on the boolean's value — that depends on the device/OS.)
    @Test("makeModel() is consistent with isAvailable")
    func consistency() {
        if FoundationModelsBackend.isAvailable {
            #expect(FoundationModelsBackend.makeModel() != nil)
        } else {
            #expect(FoundationModelsBackend.makeModel() == nil)
        }
    }
}
