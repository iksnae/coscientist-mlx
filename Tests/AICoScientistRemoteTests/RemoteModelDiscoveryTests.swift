import AICoScientistKit
import Foundation
import Testing
@testable import AICoScientistRemote

@Suite("Remote model discovery")
struct RemoteModelDiscoveryTests {

    private struct Stub: HTTPTransport {
        let status: Int
        let body: String
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (Data(body.utf8), response)
        }
    }

    private actor URLBox {
        private(set) var last: String?
        func set(_ value: String) { last = value }
    }
    private struct CapturingStub: HTTPTransport {
        let box: URLBox
        let body: String
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            await box.set(request.url?.absoluteString ?? "")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (Data(body.utf8), response)
        }
    }

    private let base = URL(string: "https://api.example.com/v1")!
    private let okBody = #"{"object":"list","data":[{"id":"gpt-4o"},{"id":"gpt-4o-mini"}]}"#

    @Test("Parses data[].id from a /models response")
    func parsesIds() async throws {
        let ids = try await RemoteModels.list(
            baseURL: base, apiKey: "k", transport: Stub(status: 200, body: okBody))
        #expect(ids == ["gpt-4o", "gpt-4o-mini"])
    }

    @Test("Requests the {baseURL}/models path")
    func hitsModelsPath() async throws {
        let box = URLBox()
        _ = try await RemoteModels.list(
            baseURL: base, apiKey: "k", transport: CapturingStub(box: box, body: okBody))
        #expect(await box.last == "https://api.example.com/v1/models")
    }

    @Test("Throws a clear error on a non-2xx response")
    func throwsOnError() async {
        await #expect(throws: AgentError.self) {
            _ = try await RemoteModels.list(
                baseURL: self.base, apiKey: "k",
                transport: Stub(status: 401, body: #"{"error":"bad key"}"#))
        }
    }

    @Test("An empty data array yields an empty list (degrades gracefully)")
    func emptyList() async throws {
        let ids = try await RemoteModels.list(
            baseURL: base, apiKey: "k",
            transport: Stub(status: 200, body: #"{"object":"list","data":[]}"#))
        #expect(ids.isEmpty)
    }
}
