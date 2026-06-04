import AICoScientistKit
import Foundation
import Testing

@testable import AICoScientistRemote

/// Captures the outgoing request and returns a canned response — no real network.
private actor MockTransport: HTTPTransport {
    private(set) var lastRequest: URLRequest?
    private let body: Data
    private let status: Int

    init(json: String, status: Int = 200) {
        self.body = Data(json.utf8)
        self.status = status
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (body, response)
    }
}

@Suite("RemoteLanguageModel")
struct RemoteLanguageModelTests {

    @Test("Parses content from a chat-completions response")
    func parsesContent() async throws {
        let transport = MockTransport(json: #"{"choices":[{"message":{"content":"hello world"}}]}"#)
        let model = RemoteLanguageModel(model: "gpt-x", apiKey: "k", transport: transport)
        let out = try await model.generateText(system: "s", user: "u", config: .deterministic)
        #expect(out == "hello world")
    }

    @Test("Builds a correct request: URL, bearer auth, model, system+user messages")
    func buildsRequest() async throws {
        let transport = MockTransport(json: #"{"choices":[{"message":{"content":"x"}}]}"#)
        let model = RemoteLanguageModel(
            model: "gpt-x", apiKey: "secret",
            baseURL: URL(string: "https://api.example.com/v1")!, transport: transport)
        _ = try await model.generateText(system: "SYS", user: "USR", config: .deterministic)

        let req = await transport.lastRequest
        #expect(req?.url?.absoluteString == "https://api.example.com/v1/chat/completions")
        #expect(req?.httpMethod == "POST")
        #expect(req?.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        let bodyString = String(decoding: req?.httpBody ?? Data(), as: UTF8.self)
        #expect(bodyString.contains("\"gpt-x\""))
        #expect(bodyString.contains("SYS"))
        #expect(bodyString.contains("USR"))
    }

    @Test("Throws on non-2xx status")
    func throwsOnError() async {
        let transport = MockTransport(json: #"{"error":"unauthorized"}"#, status: 401)
        let model = RemoteLanguageModel(model: "m", apiKey: "k", transport: transport)
        await #expect(throws: AgentError.self) {
            _ = try await model.generateText(system: "s", user: "u", config: .deterministic)
        }
    }

    @Test("Works behind a SchemaConstrainedDecoder (remote judge path)")
    func decoderOverRemote() async throws {
        let transport = MockTransport(
            json: #"{"choices":[{"message":{"content":"{\"winner\":\"a\",\"rationale\":\"r\"}"}}]}"#)
        let model = RemoteLanguageModel(model: "m", apiKey: "k", transport: transport)
        let decoder = SchemaConstrainedDecoder(model: model)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "judge", user: "a vs b", config: .deterministic)
        #expect(verdict.winner == .a)
    }
}
