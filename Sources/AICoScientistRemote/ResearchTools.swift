import AICoScientistKit
import Foundation

/// A scholarly/web result, normalized across providers.
struct SearchResult: Sendable, Equatable {
    let title: String
    let detail: String   // authors / venue / url
    let summary: String
}

private func format(_ results: [SearchResult], source: String) -> String {
    guard !results.isEmpty else { return "No results from \(source)." }
    return results.enumerated().map { index, r in
        let summary = r.summary.isEmpty ? "" : "\n   \(r.summary.prefix(280))"
        let detail = r.detail.isEmpty ? "" : "\n   \(r.detail)"
        return "\(index + 1). \(r.title)\(detail)\(summary)"
    }.joined(separator: "\n\n")
}

private func queryParameters() -> JSONSchema {
    .object(
        properties: [
            "query": .string(),
            "maxResults": .integer,
        ],
        required: ["query"])
}

private func string(_ data: Data) -> String { String(decoding: data, as: UTF8.self) }

// MARK: - arXiv (free, no key)

/// Searches arXiv preprints (strong for CS/ML/physics). Parses the Atom feed.
public struct ArxivSearchTool: AgentTool {
    public let name = "arxiv_search"
    public let description =
        "Search arXiv for preprints relevant to a query. Use to ground hypotheses in recent "
        + "technical literature and to check novelty. Returns titles, authors, and abstracts."
    public var parameters: JSONSchema { queryParameters() }

    private let transport: any HTTPTransport
    public init(transport: any HTTPTransport = URLSessionTransport()) { self.transport = transport }

    public func call(_ arguments: JSONValue) async throws -> String {
        let query = arguments["query"]?.stringValue ?? ""
        let max = Int(arguments["maxResults"]?.numberValue ?? 5)
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string:
            "https://export.arxiv.org/api/query?search_query=all:\(encoded)&start=0&max_results=\(max)")!
        let (data, _) = try await transport.data(for: URLRequest(url: url))
        return format(ArxivFeedParser.parse(data), source: "arXiv")
    }
}

/// Minimal Atom parser for arXiv entries.
enum ArxivFeedParser {
    static func parse(_ data: Data) -> [SearchResult] {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.results
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var results: [SearchResult] = []
        private var element = ""
        private var title = "", summary = "", published = ""
        private var authors: [String] = []
        private var inEntry = false
        private var text = ""

        func parser(_ p: XMLParser, didStartElement name: String, namespaceURI: String?,
            qualifiedName: String?, attributes: [String: String]) {
            element = name
            text = ""
            if name == "entry" {
                inEntry = true; title = ""; summary = ""; published = ""; authors = []
            }
        }
        func parser(_ p: XMLParser, foundCharacters string: String) { text += string }
        func parser(_ p: XMLParser, didEndElement name: String, namespaceURI: String?,
            qualifiedName: String?) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            switch name {
            case "title" where inEntry: title = trimmed
            case "summary": summary = trimmed
            case "published": published = String(trimmed.prefix(4))
            case "name": authors.append(trimmed)
            case "entry":
                inEntry = false
                let detail = ([authors.prefix(3).joined(separator: ", ")]
                    + (published.isEmpty ? [] : ["(\(published))"])).joined(separator: " ")
                results.append(SearchResult(
                    title: title.replacingOccurrences(of: "\n", with: " "),
                    detail: detail, summary: summary))
            default: break
            }
        }
    }
}

// MARK: - PubMed (free, no key — NCBI E-utilities)

/// Searches PubMed (biomedical/life sciences) via NCBI E-utilities (esearch + esummary).
public struct PubMedSearchTool: AgentTool {
    public let name = "pubmed_search"
    public let description =
        "Search PubMed for biomedical and life-sciences literature relevant to a query. "
        + "Returns titles, authors, and venues. Use for health/biology research goals."
    public var parameters: JSONSchema { queryParameters() }

    private let transport: any HTTPTransport
    public init(transport: any HTTPTransport = URLSessionTransport()) { self.transport = transport }

    public func call(_ arguments: JSONValue) async throws -> String {
        let query = arguments["query"]?.stringValue ?? ""
        let max = Int(arguments["maxResults"]?.numberValue ?? 5)
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let base = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
        let searchURL = URL(string:
            "\(base)/esearch.fcgi?db=pubmed&retmode=json&retmax=\(max)&term=\(encoded)")!
        let (searchData, _) = try await transport.data(for: URLRequest(url: searchURL))
        let ids = (try? JSONValue.parse(string(searchData)))?["esearchresult"]?["idlist"]
        guard case let .array(idValues)? = ids, !idValues.isEmpty else {
            return "No results from PubMed."
        }
        let idList = idValues.compactMap(\.stringValue).joined(separator: ",")
        let summaryURL = URL(string: "\(base)/esummary.fcgi?db=pubmed&retmode=json&id=\(idList)")!
        let (summaryData, _) = try await transport.data(for: URLRequest(url: summaryURL))
        return format(PubMedSummaryParser.parse(string(summaryData), order: idValues.compactMap(\.stringValue)),
            source: "PubMed")
    }
}

enum PubMedSummaryParser {
    static func parse(_ json: String, order: [String]) -> [SearchResult] {
        guard let root = try? JSONValue.parse(json), let result = root["result"] else { return [] }
        return order.compactMap { id in
            guard let entry = result[id] else { return nil }
            let title = entry["title"]?.stringValue ?? "Untitled"
            let venue = entry["source"]?.stringValue ?? ""
            let date = entry["pubdate"]?.stringValue ?? ""
            var authors = ""
            if case let .array(list)? = entry["authors"] {
                authors = list.compactMap { $0["name"]?.stringValue }.prefix(3).joined(separator: ", ")
            }
            let detail = [authors, venue, date].filter { !$0.isEmpty }.joined(separator: " · ")
            return SearchResult(title: title, detail: detail, summary: "")
        }
    }
}

// MARK: - Web search (Tavily — needs an API key)

/// General web search via Tavily (LLM-oriented). Requires an API key (from Settings/Keychain).
public struct WebSearchTool: AgentTool {
    public let name = "web_search"
    public let description =
        "Search the general web for current information relevant to a query. Use when scholarly "
        + "sources are insufficient. Returns titles, URLs, and snippets."
    public var parameters: JSONSchema { queryParameters() }

    private let apiKey: String
    private let transport: any HTTPTransport
    public init(apiKey: String, transport: any HTTPTransport = URLSessionTransport()) {
        self.apiKey = apiKey
        self.transport = transport
    }

    public func call(_ arguments: JSONValue) async throws -> String {
        guard !apiKey.isEmpty else { return "Web search is not configured (no API key)." }
        let query = arguments["query"]?.stringValue ?? ""
        let max = Int(arguments["maxResults"]?.numberValue ?? 5)
        var request = URLRequest(url: URL(string: "https://api.tavily.com/search")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "api_key": apiKey, "query": query, "max_results": max, "search_depth": "basic",
        ])
        let (data, _) = try await transport.data(for: request)
        guard case let .array(items)? = (try? JSONValue.parse(string(data)))?["results"] else {
            return "No results from web search."
        }
        let results = items.map {
            SearchResult(
                title: $0["title"]?.stringValue ?? "Untitled",
                detail: $0["url"]?.stringValue ?? "",
                summary: $0["content"]?.stringValue ?? "")
        }
        return format(results, source: "web search")
    }
}
