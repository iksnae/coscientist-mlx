import Testing
@testable import AICoScientistKit

@Suite("Decode metrics")
struct DecodeMetricsTests {

    @Test("Accumulates decodes, repairs, and failures")
    func accumulate() async {
        let m = DecodeMetrics()
        await m.recordSuccess(repairs: 0)
        await m.recordSuccess(repairs: 2)
        await m.recordFailure(repairs: 1)
        let s = await m.snapshot()
        #expect(s.decodes == 2)
        #expect(s.repairs == 3)
        #expect(s.failures == 1)
    }

    @Test("Starts at zero")
    func zero() async {
        let s = await DecodeMetrics().snapshot()
        #expect(s == .init(decodes: 0, repairs: 0, failures: 0))
    }
}
