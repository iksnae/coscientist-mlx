import Testing
@testable import AICoScientistKit

@Suite("Run guard")
struct RunGuardTests {

    @Test("Memory: block below need, warn when tight, proceed when ample")
    func memory() {
        // ~2.0 GB model → need ~2560 + 512 headroom.
        #expect(RunGuard.memory(freeMB: 500, modelApproxGB: 2.0) == .block)
        #expect(RunGuard.memory(freeMB: 2700, modelApproxGB: 2.0) == .warn)
        #expect(RunGuard.memory(freeMB: 8000, modelApproxGB: 2.0) == .proceed)
    }

    @Test("Thermal: stop only on critical")
    func thermal() {
        #expect(RunGuard.thermal(.critical) == .stop)
        #expect(RunGuard.thermal(.serious) == .proceed)
        #expect(RunGuard.thermal(.fair) == .proceed)
        #expect(RunGuard.thermal(.nominal) == .proceed)
    }
}
