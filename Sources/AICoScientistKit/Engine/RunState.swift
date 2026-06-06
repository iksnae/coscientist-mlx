import Foundation

/// One point on the live Elo trend, for charts/sparklines. Identifiable for SwiftUI `Chart`.
public struct EloTimelinePoint: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let step: Int
    public let phase: String
    public let topElo: Int
    public let avgElo: Double
    public let poolSize: Int

    public init(
        step: Int, phase: String, topElo: Int, avgElo: Double, poolSize: Int, id: UUID = UUID()
    ) {
        self.id = id
        self.step = step
        self.phase = phase
        self.topElo = topElo
        self.avgElo = avgElo
        self.poolSize = poolSize
    }
}

/// The single source of truth for the live run + download (M22). Reduced from `RunAction`s
/// dispatched by the run orchestrator; the app's `WorkflowRunner` projects these for SwiftUI.
public struct RunState: StateType {
    public var runningStudyID: UUID?
    public var status = "Idle"
    public var phase = ""
    public var detail = ""
    public var completed = 0
    public var total = 0
    public var hypotheses: [Hypothesis] = []
    public var metrics = ExecutionMetrics()
    public var errors: [String] = []
    public var activity: [ActivityEvent] = []
    public var activityStep = 0
    public var downloadProgress: Double?
    public var downloadingNeeded = false
    public var iteration = 0
    public var maxIterations = 1
    public var timeline: [EloTimelinePoint] = []

    public init() {}

    /// Progress within the current phase, 0…1, or nil when nothing is countable.
    public var phaseFraction: Double? { total > 0 ? Double(completed) / Double(total) : nil }
}

public enum RunAction: ActionType {
    case started(studyID: UUID, maxIterations: Int, downloadingNeeded: Bool, status: String)
    case status(String)
    case downloadProgress(Double?)
    case progress(WorkflowProgress)
    case finished(status: String, hypotheses: [Hypothesis], metrics: ExecutionMetrics, errors: [String])
    case cleared
}

/// Pure reducer for the run. Side-effects (loading models, running the engine, thermal cancel)
/// live in the orchestrator, which dispatches these actions.
public func runReducer(_ state: RunState, _ action: any ActionType) -> RunState {
    guard let action = action as? RunAction else { return state }
    var s = state
    switch action {
    case let .started(id, maxIterations, downloadingNeeded, status):
        s = RunState()
        s.runningStudyID = id
        s.maxIterations = max(1, maxIterations)
        s.downloadingNeeded = downloadingNeeded
        s.status = status
    case .status(let text):
        s.status = text
    case .downloadProgress(let fraction):
        s.downloadProgress = fraction
    case .progress(let p):
        s.phase = p.phase
        s.iteration = p.iteration
        s.detail = p.detail
        s.completed = p.completed
        s.total = p.total
        s.hypotheses = p.hypotheses
        s.metrics = p.metrics
        s.activity.append(ActivityEvent(step: s.activityStep, progress: p))
        s.activityStep += 1
        if s.activity.count > 200 { s.activity.removeFirst(s.activity.count - 200) }
        if !p.hypotheses.isEmpty {
            let elos = p.hypotheses.map(\.eloRating)
            s.timeline.append(
                EloTimelinePoint(
                    step: s.timeline.count, phase: p.phase, topElo: elos.max() ?? 1200,
                    avgElo: Double(elos.reduce(0, +)) / Double(elos.count), poolSize: elos.count))
        }
    case let .finished(status, hypotheses, metrics, errors):
        s.status = status
        s.hypotheses = hypotheses
        s.metrics = metrics
        s.errors = errors
        s.phase = "done"
        s.detail = ""
        s.completed = 0
        s.total = 0
    case .cleared:
        s.runningStudyID = nil
    }
    return s
}
