import Foundation
import Synchronization
import Testing
@testable import AIKit

/// Runs the real on-device model with its web search tool. Skipped unless you opt in:
///
///     TEST_RUNNER_AIKIT_LIVE_APPLE=1 xcodebuild test -scheme AIKit -destination '…'
///
/// Needs Apple Intelligence turned on (the simulator uses this Mac's). The search engine is a fake,
/// so this checks that the model calls the tool and answers from what it returned.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["AIKIT_LIVE_APPLE"] != nil))
struct LiveAppleTests {
    private nonisolated final class RecordingEngine: AIWebSearchEngine {
        let queries = Mutex<[String]>([])

        func search(_ query: String) async throws -> AIAnswer {
            queries.withLock { $0.append(query) }
            return AIAnswer(
                text: "The 2031 Tour de Lune bicycle race was won by Marta Quillfeather of Portugal on 14 July 2031.",
                sources: [AIWebSource(title: "Tour de Lune results", url: URL(string: "https://tdl.example/2031")!)]
            )
        }
    }

    @Test func onDeviceModelSearchesWithTheTool() async throws {
        let engine = RecordingEngine()
        let credentials = AIProviderCredentials(provider: .apple, model: AppleIntelligenceBackend.modelName, apiKey: nil, baseURL: nil)

        let answer = try await ProviderClient().searchWeb(
            [.user("Who won the 2031 Tour de Lune?")], system: nil,
            credentials: credentials, model: AppleIntelligenceBackend.modelName, searchEngine: engine
        )

        print("Apple searched \(engine.queries.withLock { $0 }) and replied: \(answer.text)")
        #expect(!engine.queries.withLock { $0 }.isEmpty)
        #expect(answer.text.localizedStandardContains("Quillfeather"))
        #expect(answer.sources.map(\.title) == ["Tour de Lune results"])
    }

    /// Long research instructions plus long results used to overflow the 8,192-token context.
    @Test func longResearchFitsTheContext() async throws {
        let engine = LongEngine()
        let credentials = AIProviderCredentials(provider: .apple, model: AppleIntelligenceBackend.modelName, apiKey: nil, baseURL: nil)
        let system = String(repeating: "Write a detailed buying report: authorized dealers, grey market, prices, service centers, warranty. ", count: 40)

        let answer = try await ProviderClient().searchWeb(
            [.user("Research the Glycine GL1050 for a buyer in the United States: vendors, prices and warranty.")],
            system: system, credentials: credentials, model: AppleIntelligenceBackend.modelName, searchEngine: engine
        )

        print("Apple searched \(engine.queries.withLock { $0 }) and replied \(answer.text.count) characters")
        #expect(!answer.text.isEmpty)
    }

    private nonisolated final class LongEngine: AIWebSearchEngine {
        let queries = Mutex<[String]>([])

        func search(_ query: String) async throws -> AIAnswer {
            queries.withLock { $0.append(query) }
            let text = (1...60).map { "Vendor \($0) sells the Glycine GL1050 for $\(400 + $0 * 5) with a two-year warranty and free shipping." }
            return AIAnswer(text: text.joined(separator: " "), sources: [AIWebSource(title: "Dealers", url: URL(string: "https://dealers.example")!)])
        }
    }
}
