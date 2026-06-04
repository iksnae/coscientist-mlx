/// Thread-safe collector for structured-decoding telemetry. Decoders report each decode and
/// how many repair retries it needed; callers read a `Snapshot` afterwards. An `actor` so it
/// can be shared across the engine's concurrent agent calls.
public actor DecodeMetrics {
    public private(set) var decodeCount = 0
    public private(set) var repairAttempts = 0
    public private(set) var failureCount = 0

    public init() {}

    /// Record a decode that ultimately produced a value, using `repairs` retries (0 = clean).
    func recordSuccess(repairs: Int) {
        decodeCount += 1
        repairAttempts += repairs
    }

    /// Record a decode that never produced a value after `repairs` retries.
    func recordFailure(repairs: Int) {
        failureCount += 1
        repairAttempts += repairs
    }

    public func snapshot() -> Snapshot {
        Snapshot(decodes: decodeCount, repairs: repairAttempts, failures: failureCount)
    }

    public struct Snapshot: Sendable, Equatable {
        public let decodes: Int
        public let repairs: Int
        public let failures: Int
    }
}
