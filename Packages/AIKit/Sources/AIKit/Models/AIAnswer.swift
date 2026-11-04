import Foundation

/// A reply from `AIProviderStore.searchWeb(_:)`: the answer, plus the web pages it came from.
public nonisolated struct AIAnswer: Sendable, Equatable, Codable {
    public var text: String
    /// Pages the provider searched or read, in the order it cited them. Show them as links.
    public var sources: [AIWebSource]

    public init(text: String, sources: [AIWebSource] = []) {
        self.text = text
        self.sources = sources
    }
}

/// One web page an answer used.
public nonisolated struct AIWebSource: Sendable, Hashable, Codable, Identifiable {
    public var title: String
    public var url: URL

    public var id: URL { url }

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }

    /// Skips links that aren't web addresses, falls back to the site name for a missing title,
    /// and keeps only the first of each URL.
    static func list(_ pairs: [(title: String?, url: String?)]) -> [AIWebSource] {
        var seen = Set<URL>()
        return pairs.compactMap { pair in
            guard let url = pair.url.flatMap(URL.init(string:)),
                  url.scheme?.hasPrefix("http") == true,
                  seen.insert(url).inserted else { return nil }
            let title = pair.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            return AIWebSource(title: title?.isEmpty == false ? title! : url.host() ?? url.absoluteString, url: url)
        }
    }
}
