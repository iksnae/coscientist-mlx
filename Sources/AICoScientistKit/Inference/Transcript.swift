/// One model interaction: the system + user prompt sent and the raw response received.
public struct TranscriptEntry: Codable, Sendable, Equatable {
    public let system: String
    public let user: String
    public let response: String

    public init(system: String, user: String, response: String) {
        self.system = system
        self.user = user
        self.response = response
    }
}

/// Append-only log of model interactions, the typed equivalent of the reference's
/// `conversation_history`. An `actor` so it's shared safely across concurrent agent calls;
/// opt-in (decoders only record if given one).
public actor Transcript {
    public private(set) var entries: [TranscriptEntry] = []

    public init() {}

    func record(system: String, user: String, response: String) {
        entries.append(TranscriptEntry(system: system, user: user, response: response))
    }

    public func all() -> [TranscriptEntry] { entries }
}
