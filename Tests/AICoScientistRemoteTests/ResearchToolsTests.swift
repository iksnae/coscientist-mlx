import AICoScientistKit
import Foundation
import Testing
@testable import AICoScientistRemote

private struct StubTransport: HTTPTransport {
    let responses: [(match: String, body: String)]
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let url = request.url?.absoluteString ?? ""
        let body = responses.first { url.contains($0.match) }?.body ?? ""
        let response = HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }
}

private func args(_ query: String) -> JSONValue { .object(["query": .string(query)]) }

@Suite("Research tools")
struct ResearchToolsTests {

    @Test("arXiv search parses the Atom feed")
    func arxiv() async throws {
        let feed = """
            <?xml version="1.0"?>
            <feed xmlns="http://www.w3.org/2005/Atom">
              <entry>
                <title>Better Batteries via Solid Electrolytes</title>
                <summary>We propose a novel solid electrolyte.</summary>
                <published>2024-03-01T00:00:00Z</published>
                <author><name>Ada Lovelace</name></author>
              </entry>
            </feed>
            """
        let tool = ArxivSearchTool(transport: StubTransport(responses: [("export.arxiv.org", feed)]))
        let output = try await tool.call(args("solid electrolytes"))
        #expect(output.contains("Better Batteries via Solid Electrolytes"))
        #expect(output.contains("Ada Lovelace"))
        #expect(output.contains("novel solid electrolyte"))
        #expect(output.contains("2024"))
    }

    @Test("PubMed search chains esearch + esummary")
    func pubmed() async throws {
        let esearch = #"{"esearchresult":{"idlist":["111"]}}"#
        let esummary = """
            {"result":{"111":{"title":"Gene Therapy for X","source":"Nature",
            "pubdate":"2023","authors":[{"name":"Jane Doe"}]}}}
            """
        let tool = PubMedSearchTool(transport: StubTransport(responses: [
            ("esearch.fcgi", esearch), ("esummary.fcgi", esummary),
        ]))
        let output = try await tool.call(args("gene therapy"))
        #expect(output.contains("Gene Therapy for X"))
        #expect(output.contains("Jane Doe"))
        #expect(output.contains("Nature"))
    }

    @Test("Web search parses provider results")
    func web() async throws {
        let body = #"{"results":[{"title":"Result A","url":"https://example.com","content":"a snippet"}]}"#
        let tool = WebSearchTool(
            apiKey: "k", transport: StubTransport(responses: [("api.tavily.com", body)]))
        let output = try await tool.call(args("query"))
        #expect(output.contains("Result A"))
        #expect(output.contains("https://example.com"))
    }

    @Test("Web search without a key is a no-op, not a crash")
    func webNoKey() async throws {
        let tool = WebSearchTool(apiKey: "", transport: StubTransport(responses: []))
        let output = try await tool.call(args("query"))
        #expect(output.localizedCaseInsensitiveContains("not configured"))
    }
}
