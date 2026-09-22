import Foundation
import Testing
@testable import AIKit

/// Real round-trips against the cloud providers with your own keys. Each test only runs
/// when its key is set; pass them with the TEST_RUNNER_ prefix so they reach the simulator:
///
///     TEST_RUNNER_OPENAI_API_KEY=sk-… \
///     TEST_RUNNER_ANTHROPIC_API_KEY=sk-ant-… \
///     TEST_RUNNER_GEMINI_API_KEY=AIza… \
///     TEST_RUNNER_MISTRAL_API_KEY=… \
///     TEST_RUNNER_OPENROUTER_API_KEY=sk-or-… \
///     xcodebuild test -scheme AIKit -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
///
/// Each test checks the key (model list), then sends one tiny prompt. Override the model
/// with e.g. TEST_RUNNER_OPENAI_MODEL=… ; otherwise a small/cheap one is picked from the list.
/// Goes through ProviderClient directly so no Keychain entitlement is needed in tests.
@MainActor
struct LiveCloudTests {
    private nonisolated static let env = ProcessInfo.processInfo.environment

    @Test(.enabled(if: env["OPENAI_API_KEY"] != nil))
    func openAI() async throws {
        try await roundTrip(.openAI, keyVar: "OPENAI_API_KEY", modelVar: "OPENAI_MODEL",
                            prefer: { $0.hasPrefix("gpt-") && $0.contains("mini") })
    }

    @Test(.enabled(if: env["ANTHROPIC_API_KEY"] != nil))
    func anthropic() async throws {
        try await roundTrip(.anthropic, keyVar: "ANTHROPIC_API_KEY", modelVar: "ANTHROPIC_MODEL",
                            prefer: { $0.contains("haiku") })
    }

    @Test(.enabled(if: env["GEMINI_API_KEY"] != nil))
    func gemini() async throws {
        try await roundTrip(.gemini, keyVar: "GEMINI_API_KEY", modelVar: "GEMINI_MODEL",
                            prefer: { $0.contains("flash") && !$0.contains("image") && !$0.contains("tts") })
    }

    @Test(.enabled(if: env["MISTRAL_API_KEY"] != nil))
    func mistral() async throws {
        try await roundTrip(.mistral, keyVar: "MISTRAL_API_KEY", modelVar: "MISTRAL_MODEL",
                            prefer: { $0.contains("small-latest") })
    }

    @Test(.enabled(if: env["OPENROUTER_API_KEY"] != nil))
    func openRouter() async throws {
        try await roundTrip(.openRouter, keyVar: "OPENROUTER_API_KEY", modelVar: "OPENROUTER_MODEL",
                            prefer: { $0.hasSuffix(":free") })
    }

    private func roundTrip(
        _ provider: AIProvider,
        keyVar: String,
        modelVar: String,
        prefer: (String) -> Bool
    ) async throws {
        let key = try #require(Self.env[keyVar])
        let client = ProviderClient()

        // 1. Same call the Connect button makes.
        let models = try await client.fetchModels(for: provider, apiKey: key, baseURL: nil)
        #expect(!models.isEmpty, "\(provider.displayName) returned no models")

        // 2. Same call AIProviderStore.send makes.
        let model = try #require(Self.env[modelVar] ?? models.first(where: prefer) ?? models.first)
        let credentials = AIProviderCredentials(provider: provider, model: model, apiKey: key,
                                                baseURL: provider.defaultAPIBaseURL)
        let reply = try await client.chat([.user("Reply with the single word: pong")],
                                          system: "You are terse.", credentials: credentials, model: model)

        print("\(provider.displayName) \(model) replied: \(reply)")
        #expect(!reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
