import Foundation

/// After a web search, Claude sometimes writes its citations inline as `<cite index="2-4">…</cite>`
/// instead of returning them as structured citations. The sources are reported separately, so the
/// tags are dropped and the cited words kept. Only `index` pairs match, so a real HTML `<cite>` survives.
nonisolated enum CitationMarkup {
    static func stripped(_ text: String) -> String {
        text.replacing(/<cite index="[^"]*">(.*?)<\/cite>/.dotMatchesNewlines()) { $0.output.1 }
    }
}
