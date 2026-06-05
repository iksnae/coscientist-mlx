import Testing
@testable import AICoScientistKit

@Suite("Redux store")
@MainActor
struct StoreTests {

    struct CounterState: StateType, Equatable {
        var count = 0
        var note = ""
    }
    enum CounterAction: ActionType, Equatable {
        case increment
        case add(Int)
        case setNote(String)
    }
    nonisolated static func reduce(_ state: CounterState, _ action: any ActionType) -> CounterState {
        var s = state
        switch action as? CounterAction {
        case .increment: s.count += 1
        case .add(let n): s.count += n
        case .setNote(let t): s.note = t
        case .none: break
        }
        return s
    }

    /// Test collector for dispatched actions (single-threaded in tests).
    final class Box: @unchecked Sendable { var notes: [String] = [] }

    @Test("Dispatch runs the reducer and updates state")
    func reduces() {
        let store = Store(initial: CounterState(), reduce: Self.reduce)
        store.dispatch(CounterAction.increment)
        store.dispatch(CounterAction.add(4))
        #expect(store.state.count == 5)
    }

    @Test("Reducer is pure — testable without a store")
    func pureReducer() {
        let next = Self.reduce(CounterState(count: 2), CounterAction.add(3))
        #expect(next.count == 5)
    }

    @Test("Middleware receives the action + post-reduce state and can dispatch a follow-up")
    func middlewareContract() async {
        let box = Box()
        let dispatch: Dispatch = { action in
            if case CounterAction.setNote(let t) = action { box.notes.append(t) }
        }
        let mw: Middleware<CounterState> = { action, state, dispatch in
            if case CounterAction.increment = action, state.count == 1 {
                dispatch(CounterAction.setNote("hit"))
            }
        }
        await mw(CounterAction.increment, CounterState(count: 1), dispatch)
        #expect(box.notes == ["hit"])
    }

    @Test("Store async dispatch reduces, then awaits middleware against the new state")
    func storeAwaitsMiddleware() async {
        let box = Box()
        let mw: Middleware<CounterState> = { action, state, _ in
            if case CounterAction.increment = action { box.notes.append("saw:\(state.count)") }
        }
        let store = Store(initial: CounterState(), reduce: Self.reduce, middleware: [mw])
        await store.dispatch(CounterAction.increment)
        #expect(store.state.count == 1)
        #expect(box.notes == ["saw:1"])  // middleware saw the post-reduce state
    }
}
