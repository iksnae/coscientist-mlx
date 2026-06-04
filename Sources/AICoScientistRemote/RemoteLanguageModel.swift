import AICoScientistKit
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// HTTP transport seam, so `RemoteLanguageModel` is unit-testable without real networking (DIP).
public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Default transport over `URLSession`.
public struct URLSessionTransport: HTTPTransport {
    public init() {}
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

/// A hosted `LanguageModel` speaking the OpenAI-compatible Chat Completions API (OpenAI,
/// OpenRouter, local servers, etc.). Used for the hybrid split — e.g. a strong remote judge
/// for the tournament while generation stays on-device. No MLX dependency.
public struct RemoteLanguageModel: AICoScientistKit.LanguageModel {
    private let model: String
    private let apiKey: String
    private let baseURL: URL
    private let transport: any HTTPTransport

    /// - Parameters:
    ///   - model: the remote model id (e.g. `gpt-4o`).
    ///   - apiKey: bearer token; defaults to `OPENAI_API_KEY` from the environment.
    ///   - baseURL: API root; defaults to OpenAI's `/v1`.
    public init(
        model: String,
        apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.transport = transport
    }

    public func generateText(
        system: String, user: String, config: GenerationConfig
    ) async throws -> String {
        let body = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user),
            ],
            temperature: config.temperature,
            maxTokens: config.maxTokens,
            seed: config.seed
        )

        var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AgentError.generationFailed("no HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let snippet = String(decoding: data, as: UTF8.self).prefix(200)
            throw AgentError.generationFailed("HTTP \(http.statusCode): \(snippet)")
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AgentError.generationFailed("response had no choices")
        }
        return content
    }
}

// MARK: - Wire types

private struct ChatRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int
    let seed: UInt64?

    struct Message: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, seed
        case maxTokens = "max_tokens"
    }
}

private struct ChatResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable { let message: Message }
    struct Message: Decodable { let content: String }
}
