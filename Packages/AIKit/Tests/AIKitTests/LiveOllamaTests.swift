import Foundation
import Testing
@testable import AIKit

/// Talks to a real Ollama server. Skipped unless you opt in:
///
///     TEST_RUNNER_AIKIT_LIVE_OLLAMA=1 xcodebuild test -scheme AIKit -destination '…'
///
/// Needs `ollama serve` on this Mac with at least one model pulled (e.g. `ollama pull smollm:135m`).
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["AIKIT_LIVE_OLLAMA"] != nil))
struct LiveOllamaTests {
    @Test func connectAndGetARealReply() async throws {
        let store = AIProviderStore(providers: [.ollama], defaults: UserDefaults(suiteName: "AIKitLive.\(UUID().uuidString)")!)

        try await store.connect(.ollama, apiKey: nil, baseURL: "http://localhost:11434")
        let model = try #require(store.activeCredentials?.model)

        let reply = try await store.send("Say hello in one short sentence.", system: "You are terse.")

        print("Ollama \(model) replied: \(reply)")
        #expect(!reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
