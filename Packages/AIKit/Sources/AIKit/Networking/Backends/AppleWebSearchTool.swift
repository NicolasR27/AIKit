import Foundation
import FoundationModels
import Synchronization

/// The on-device model's web search: a Foundation Models tool it calls when it decides it needs
/// live information. The search itself runs through an `AIWebSearchEngine`.
nonisolated struct AppleWebSearchTool: Tool {
    let engine: any AIWebSearchEngine
    /// Every page the searches used, so the reply can list them.
    let log = SourceLog()

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

    func call(arguments: Arguments) async throws -> String {
        let answer = try await engine.search(arguments.query)
        log.append(answer.sources)
        return Self.output(for: answer)
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
