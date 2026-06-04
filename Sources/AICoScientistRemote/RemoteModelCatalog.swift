import AICoScientistKit
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Discovery for an OpenAI-compatible provider: lists the models a hosted endpoint offers,
/// so users pick from a real list instead of typing an id. Reuses the `HTTPTransport` seam,
/// so it is unit-testable without networking.
public enum RemoteModels {
    /// Fetch the available model ids via `GET {baseURL}/models`. Decodes `data[].id`
    /// defensively; a non-2xx response throws a clear error, and an empty list returns `[]`
    /// so callers can degrade to free-text entry.
    public static func list(
        baseURL: URL,
        apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
        transport: any HTTPTransport = URLSessionTransport()
    ) async throws -> [String] {
        var request = URLRequest(url: baseURL.appendingPathComponent("models"))
        request.httpMethod = "GET"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AgentError.generationFailed("no HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let snippet = String(decoding: data, as: UTF8.self).prefix(200)
            throw AgentError.generationFailed("HTTP \(http.statusCode): \(snippet)")
        }
        return try JSONDecoder().decode(ModelsResponse.self, from: data).data.map(\.id)
    }
}

private struct ModelsResponse: Decodable {
    let data: [Entry]
    struct Entry: Decodable { let id: String }
}
