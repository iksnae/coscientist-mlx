import Observation

/// A minimal, unidirectional (Redux-style) state container, adapted from the operator's pattern
/// (https://iksnae.com/2022/12/04/swift-redux-protocols/) to Swift 6 + the Observation framework.
///
/// State changes flow one way: `dispatch(action)` → pure `reduce(state, action)` → published
/// `state`. Side-effects (running the engine, downloading models, persistence) live only in
/// **async middleware**, which observes each action + the post-reduce state and may `dispatch`
/// follow-up actions (e.g. streaming progress). Reducers stay pure + unit-testable; the store is
/// the single source of truth that SwiftUI observes.

/// Marker for a state value. `Sendable` so it can cross actor boundaries into middleware.
public protocol StateType: Sendable {}

/// Marker for an action. `Sendable` so actions can be dispatched from background side-effects.
public protocol ActionType: Sendable {}

/// A pure state transition.
public typealias Reduce<S: StateType> = @Sendable (S, any ActionType) -> S

/// Dispatch a (follow-up) action. Safe to call from any context — it hops to the store's actor.
public typealias Dispatch = @Sendable (any ActionType) -> Void

/// An async side-effect: observes an action + the post-reduce state, and may dispatch follow-ups
/// (including streaming progress over time). Pure-logic reducers + side-effects-only middleware
/// is the whole point.
public typealias Middleware<S: StateType> = @Sendable (any ActionType, S, @escaping Dispatch) async -> Void

@MainActor
@Observable
public final class Store<S: StateType> {
    public private(set) var state: S
    private let reduceFn: Reduce<S>
    private let middleware: [Middleware<S>]

    public init(initial: S, reduce: @escaping Reduce<S>, middleware: [Middleware<S>] = []) {
        self.state = initial
        self.reduceFn = reduce
        self.middleware = middleware
    }

    /// A dispatcher safe to capture in middleware: re-enters the store on the main actor.
    private var dispatcher: Dispatch {
        { [weak self] action in Task { @MainActor in self?.dispatch(action) } }
    }

    /// Reduce synchronously (state updates immediately for SwiftUI), then fire middleware
    /// side-effects without blocking.
    public func dispatch(_ action: any ActionType) {
        state = reduceFn(state, action)
        guard !middleware.isEmpty else { return }
        let snapshot = state
        let dispatch = dispatcher
        for mw in middleware { Task { await mw(action, snapshot, dispatch) } }
    }

    /// Reduce, then await every middleware (so callers can await side-effects completing).
    public func dispatch(_ action: any ActionType) async {
        state = reduceFn(state, action)
        let snapshot = state
        let dispatch = dispatcher
        for mw in middleware { await mw(action, snapshot, dispatch) }
    }
}
