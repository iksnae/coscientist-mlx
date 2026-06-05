/// Pure resolver for the hosted (OpenAI-compatible) model ids a picker should offer.
///
/// The UI was gating its "Hosted" section on a fetched list that only populated after a manual
/// Settings refresh — so hosted models never appeared on a fresh launch. This centralises the
/// rule (UI-free, testable): when the provider is ready, always offer the configured default
/// model plus any fetched/cached ids, configured-first and de-duplicated; otherwise nothing.
public enum HostedModels {
    /// - Parameters:
    ///   - ready: whether a usable provider is configured (base URL + key + model present).
    ///   - configured: the configured default model id (may be blank).
    ///   - fetched: model ids discovered from / cached for the provider.
    /// - Returns: the hosted ids to show, configured-first, de-duplicated; empty when not ready.
    public static func options(ready: Bool, configured: String, fetched: [String]) -> [String] {
        guard ready else { return [] }
        var result: [String] = []
        var seen = Set<String>()
        func add(_ id: String) {
            let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { return }
            result.append(trimmed)
        }
        add(configured)
        fetched.forEach(add)
        return result
    }
}
