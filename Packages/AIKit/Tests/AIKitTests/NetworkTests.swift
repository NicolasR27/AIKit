import Foundation
import Testing
@testable import AIKit

/// Everything that goes through `StubURLProtocol` shares its static handler, so run serially.
@MainActor
@Suite(.serialized)
struct NetworkTests {
    // MARK: - ProviderClient

    @Test func openAIModelsAreSortedAndUseBearerAuth() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"data":[{"id":"gpt-b"},{"id":"gpt-a"}]}"#)
        })

        let models = try await client.fetchModels(for: .openAI, apiKey: "sk-test", baseURL: nil)

        #expect(models == ["gpt-a", "gpt-b"])
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.url?.absoluteString == "https://api.openai.com/v1/models")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
    }

    @Test func anthropicKeepsNewestFirstOrderAndSendsVersionHeader() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"data":[{"id":"claude-new"},{"id":"claude-old"}],"has_more":false}"#)
        })

        let models = try await client.fetchModels(for: .anthropic, apiKey: "sk-ant-test", baseURL: nil)

        #expect(models == ["claude-new", "claude-old"])
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-ant-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
    }

    @Test func geminiDropsNonChatModelsAndStripsPrefix() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"""
            {"models":[
              {"name":"models/gemini-pro","supportedGenerationMethods":["generateContent"]},
              {"name":"models/text-embedding","supportedGenerationMethods":["embedContent"]}
            ]}
            """#)
        })

        let models = try await client.fetchModels(for: .gemini, apiKey: "AIza-test", baseURL: nil)

        #expect(models == ["gemini-pro"])
    }

    @Test func ollamaUsesCustomServerAndTrimsTrailingSlash() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"models":[{"name":"llama3:latest"}]}"#)
        })

        let models = try await client.fetchModels(for: .ollama, apiKey: nil, baseURL: "http://10.0.0.5:11434/")

        #expect(models == ["llama3:latest"])
        #expect(StubURLProtocol.requests.first?.url?.absoluteString == "http://10.0.0.5:11434/api/tags")
    }

    @Test func unauthorizedSurfacesProviderMessage() async {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(status: 401, json: #"{"error":{"message":"Incorrect API key provided"}}"#)
        })

        await #expect {
            try await client.fetchModels(for: .openAI, apiKey: "sk-bad", baseURL: nil)
        } throws: { error in
            guard case ProviderError.invalidKey(let message) = error else { return false }
            return message == "Incorrect API key provided"
        }
    }

    @Test func missingKeyFailsWithoutNetwork() async {
        let client = ProviderClient(session: StubURLProtocol.session { _ in .init() })

        await #expect {
            try await client.fetchModels(for: .mistral, apiKey: "", baseURL: nil)
        } throws: { error in
            guard case ProviderError.missingKey = error else { return false }
            return true
        }
        #expect(StubURLProtocol.requests.isEmpty)
    }

    // MARK: - OpenRouter OAuth exchange

    @Test func exchangePostsCodeAndReturnsKey() async throws {
        let session = StubURLProtocol.session { _ in .init(json: #"{"key":"sk-or-minted"}"#) }
        let auth = OpenRouterAuth(callbackScheme: "aikit", keyLabel: "Tests")

        let key = try await auth.exchange(
            callbackURL: URL(string: "aikit://oauth/openrouter?code=abc123")!,
            session: session
        )

        #expect(key == "sk-or-minted")
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://openrouter.ai/api/v1/auth/keys")
    }

    @Test func exchangeWithoutCodeThrows() async {
        let session = StubURLProtocol.session { _ in .init() }
        let auth = OpenRouterAuth(callbackScheme: "aikit", keyLabel: "Tests")

        await #expect(throws: ProviderError.self) {
            try await auth.exchange(callbackURL: URL(string: "aikit://oauth/openrouter")!, session: session)
        }
        #expect(StubURLProtocol.requests.isEmpty)
    }

    // MARK: - AIProviderStore (Ollama needs no key, so no Keychain in tests)

    private func makeStore(models: [String] = ["llama3", "mistral"]) -> (AIProviderStore, UserDefaults) {
        let defaults = UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!
        let store = AIProviderStore(providers: [.ollama, .openAI], defaults: defaults)
        let json = #"{"models":["# + models.map { #"{"name":"\#($0)"}"# }.joined(separator: ",") + "]}"
        store.client = ProviderClient(session: StubURLProtocol.session { _ in .init(json: json) })
        return (store, defaults)
    }

    @Test func connectMarksProviderConnectedAndDefault() async throws {
        let (store, _) = makeStore()

        try await store.connect(.ollama, apiKey: nil, baseURL: "http://192.168.1.2:11434")

        #expect(store.isConnected(.ollama))
        #expect(store.activeProvider == .ollama)
        let credentials = try #require(store.activeCredentials)
        #expect(credentials.model == "llama3")
        #expect(credentials.apiKey == nil)
        #expect(credentials.baseURL?.absoluteString == "http://192.168.1.2:11434")
    }

    @Test func settingsPersistAcrossStoreInstances() async throws {
        let (store, defaults) = makeStore()
        try await store.connect(.ollama, apiKey: nil, baseURL: nil)
        store.selectModel("mistral", for: .ollama)

        let reloaded = AIProviderStore(providers: [.ollama, .openAI], defaults: defaults)

        #expect(reloaded.isConnected(.ollama))
        #expect(reloaded.activeProvider == .ollama)
        #expect(reloaded.activeCredentials?.model == "mistral")
    }

    @Test func setDefaultAndDisconnect() async throws {
        let (store, _) = makeStore()
        try await store.connect(.ollama, apiKey: nil, baseURL: nil)

        store.setDefault(.ollama, false)
        #expect(store.activeProvider == nil)
        store.setDefault(.ollama, true)
        #expect(store.isDefault(.ollama))

        store.disconnect(.ollama)
        #expect(!store.isConnected(.ollama))
        #expect(store.activeProvider == nil)
        #expect(store.activeCredentials == nil)
    }

    @Test func failedConnectLeavesProviderDisconnected() async {
        let defaults = UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!
        let store = AIProviderStore(providers: [.ollama], defaults: defaults)
        store.client = ProviderClient(session: StubURLProtocol.session { _ in .init(status: 500) })

        await #expect(throws: ProviderError.self) {
            try await store.connect(.ollama, apiKey: nil, baseURL: nil)
        }
        #expect(!store.isConnected(.ollama))
        #expect(store.activeProvider == nil)
    }
}
