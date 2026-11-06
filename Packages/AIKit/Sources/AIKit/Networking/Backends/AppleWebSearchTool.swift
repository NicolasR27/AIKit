import Foundation
import FoundationModels
import Synchronization

/// The on-device model's web search: a Foundation Models tool it calls when it decides it needs
/// live information. The search itself runs through an `AIWebSearchEngine`.
nonisolated struct AppleWebSearchTool: Tool {
    let engine: any AIWebSearchEngine
    /// Every page the searches used, so the reply can list them.
    let log = SourceLog()
    /// Tokens the search results may still take up. The backend sets it from what's left of the
    /// on-device model's context once the conversation and room for the reply are counted.
    let budget = TokenBudget()
    /// Counts tokens the way the on-device model does. Tests swap in an estimate.
    var measure: @Sendable (String) async throws -> Int = { try await SystemLanguageModel.default.tokenCount(for: $0) }

    let name = "searchWeb"
    let description = """
        Searches the live web and returns what current pages say. Use it for news, prices, scores, \
        schedules, people, products, places, or anything that may have changed recently.
        """

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "What to look up, written as a short search query")
        var query: String
    }

    /// Findings are trimmed because the on-device model's context is small.
    static let maxFindingsLength = 1_500
    /// Rough cost of the call itself (name, arguments, wrapping) on top of what it returns.
    static let callOverhead = 60
    /// Below this, a search couldn't return anything useful, so the model is told to answer instead.
    static let minimumResultTokens = 120
    static let budgetSpent = "No more searches fit. Answer now using what the earlier searches found."

    func call(arguments: Arguments) async throws -> String {
        let allowed = budget.remaining - Self.callOverhead
        // Skip the search (and its cost) once the results couldn't fit anyway.
        guard allowed >= Self.minimumResultTokens else { return Self.budgetSpent }
        let answer = try await engine.search(arguments.query)
        log.append(answer.sources)
        let output = try await fitted(Self.output(for: answer), to: allowed)
        budget.spend(try await measure(output) + Self.callOverhead)
        return output
    }

    /// Cuts `text` down until it's at most `limit` tokens.
    func fitted(_ text: String, to limit: Int) async throws -> String {
        var text = text
        var tokens = try await measure(text)
        while tokens > limit, !text.isEmpty {
            let keep = Int(Double(text.count) * Double(limit) / Double(tokens) * 0.9)
            text = String(text.prefix(max(0, min(keep, text.count - 1))))
            tokens = try await measure(text)
        }
        return text
    }

    static func output(for answer: AIAnswer) -> String {
        var text = String(answer.text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxFindingsLength))
        if text.isEmpty { text = "The search found nothing relevant." }
        let titles = answer.sources.prefix(5).map(\.title)
        return titles.isEmpty ? text : text + "\n\nSources: " + titles.joined(separator: "; ")
    }

    /// Tells the model it has the tool and should use it rather than answer from memory.
    static let directive = """
        You have a searchWeb tool that searches the live web. Call it before you answer anything current, \
        specific or checkable (news, prices, scores, dates, people, products, places), and base your answer \
        on what it returns. Never say you can't browse the web.
        """

    static func steered(_ system: String?) -> String {
        guard let system, !system.isEmpty else { return directive }
        return directive + "\n\n" + system
    }
}

nonisolated final class TokenBudget: Sendable {
    private let tokens = Mutex(0)

    var remaining: Int { tokens.withLock { $0 } }

    func set(_ value: Int) {
        tokens.withLock { $0 = max(0, value) }
    }

    func spend(_ cost: Int) {
        tokens.withLock { $0 = max(0, $0 - cost) }
    }
}

nonisolated final class SourceLog: Sendable {
    private let pages = Mutex<[AIWebSource]>([])

    func append(_ sources: [AIWebSource]) {
        pages.withLock { $0 += sources }
    }

    /// Pages in the order the searches returned them, without repeats.
    var sources: [AIWebSource] {
        AIWebSource.list(pages.withLock { $0 }.map { ($0.title, $0.url.absoluteString) })
    }
}
