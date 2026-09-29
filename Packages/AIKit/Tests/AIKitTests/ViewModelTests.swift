import Foundation
import Testing
@testable import AIKit

/// Keeps keys in memory so tests can cover key-based providers without the Keychain.
final class InMemoryKeyStorage: APIKeyStorage {
    var keys: [AIProvider: String] = [:]

    func read(_ provider: AIProvider) -> String? { keys[provider] }
    func save(_ key: String, for provider: AIProvider) throws { keys[provider] = key }
    func delete(_ provider: AIProvider) { keys[provider] = nil }
}

@MainActor
func makeTestStore(
    _ providers: [AIProvider] = [.ollama, .openAI],
    keys: InMemoryKeyStorage = InMemoryKeyStorage()
) -> AIProviderStore {
    AIProviderStore(
        providers: providers,
        openRouterCallbackScheme: "aikit",
        openRouterKeyLabel: "Tests",
        defaults: UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!,
        keys: keys
    )
}

// Nested in NetworkTests so it inherits `.serialized` (shared StubURLProtocol handler).
extension NetworkTests {
@MainActor
@Suite struct KeyStorageTests {
    private let modelsJSON = #"{"data":[{"id":"gpt-a"}]}"#

    @Test func connectSavesTrimmedKeyAndShowsHint() async throws {
        let keys = InMemoryKeyStorage()
        let store = makeTestStore(keys: keys)
        store.client = ProviderClient(session: StubURLProtocol.session { _ in .init(json: modelsJSON) })

        try await store.connect(.openAI, apiKey: "  sk-test1234\n", baseURL: nil)

        #expect(keys.keys[.openAI] == "sk-test1234")
        #expect(store.maskedKey(for: .openAI) == "••••1234")
        #expect(store.activeCredentials?.apiKey == "sk-test1234")
    }

    @Test func reconnectWithoutTypingReusesStoredKey() async throws {
        let keys = InMemoryKeyStorage()
        keys.keys[.openAI] = "sk-saved"
        let store = makeTestStore(keys: keys)
        store.client = ProviderClient(session: StubURLProtocol.session { _ in .init(json: modelsJSON) })

        try await store.connect(.openAI, apiKey: "", baseURL: nil)

        #expect(StubURLProtocol.requests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer sk-saved")
    }

    @Test func disconnectDeletesKey() async throws {
        let keys = InMemoryKeyStorage()
        let store = makeTestStore(keys: keys)
        store.client = ProviderClient(session: StubURLProtocol.session { _ in .init(json: modelsJSON) })
        try await store.connect(.openAI, apiKey: "sk-test", baseURL: nil)

        store.disconnect(.openAI)

        #expect(keys.keys[.openAI] == nil)
        #expect(!store.hasStoredKey(for: .openAI))
    }
}

@MainActor
@Suite struct ProviderDetailViewModelTests {
    @Test func connectNeedsAKeyUnlessOneIsSaved() {
        let keys = InMemoryKeyStorage()
        let viewModel = ProviderDetailViewModel(store: makeTestStore(keys: keys), provider: .openAI)
        #expect(!viewModel.canConnect)

        viewModel.keyDraft = "   "
        #expect(!viewModel.canConnect)

        viewModel.keyDraft = "sk-test"
        #expect(viewModel.canConnect)

        keys.keys[.openAI] = "sk-saved"
        let saved = ProviderDetailViewModel(store: makeTestStore(keys: keys), provider: .openAI)
        #expect(saved.canConnect)
        #expect(saved.keyPrompt.contains("••••aved"))
    }

    @Test func successfulConnectClearsDraftAndConnects() async {
        let store = makeTestStore()
        store.client = ProviderClient(session: StubURLProtocol.session { _ in .init(json: #"{"data":[{"id":"gpt-a"}]}"#) })
        let viewModel = ProviderDetailViewModel(store: store, provider: .openAI)
        viewModel.keyDraft = "sk-test"
        viewModel.revealsKey = true

        viewModel.requestConnect()
        #expect(viewModel.isChecking)
        #expect(!viewModel.canConnect)
        await viewModel.runRequestedConnect()

        #expect(viewModel.isConnected)
        #expect(viewModel.keyDraft.isEmpty)
        #expect(!viewModel.revealsKey)
        #expect(!viewModel.isChecking)
        #expect(viewModel.showsConnectSuccess)
        #expect(viewModel.selectedModel == "gpt-a")
        #expect(viewModel.connectTitle == .testConnection)
    }

    @Test func failedConnectShowsErrorAndKeepsDraft() async {
        let store = makeTestStore()
        store.client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(status: 401, json: #"{"error":{"message":"Incorrect API key provided"}}"#)
        })
        let viewModel = ProviderDetailViewModel(store: store, provider: .openAI)
        viewModel.keyDraft = "sk-bad"

        viewModel.requestConnect()
        await viewModel.runRequestedConnect()

        #expect(!viewModel.isConnected)
        #expect(viewModel.keyDraft == "sk-bad")
        #expect(viewModel.errorMessage?.contains("Incorrect API key provided") == true)
    }

    @Test func runWithoutRequestDoesNothing() async {
        let store = makeTestStore()
        store.client = ProviderClient(session: StubURLProtocol.session { _ in .init() })
        let viewModel = ProviderDetailViewModel(store: store, provider: .ollama)

        await viewModel.runRequestedConnect()

        #expect(StubURLProtocol.requests.isEmpty)
    }

    @Test func defaultToggleAndDisconnect() async throws {
        let store = makeTestStore()
        store.client = ProviderClient(session: StubURLProtocol.session { _ in .init(json: #"{"models":[{"name":"llama3"}]}"#) })
        let viewModel = ProviderDetailViewModel(store: store, provider: .ollama)
        #expect(viewModel.baseURLDraft == "http://localhost:11434")

        viewModel.requestConnect()
        await viewModel.runRequestedConnect()
        #expect(viewModel.isDefault)

        viewModel.isDefault = false
        #expect(store.activeProvider == nil)

        viewModel.disconnect()
        #expect(!viewModel.isConnected)
    }
}
}

@MainActor
struct ProviderListViewModelTests {
    private func makeStore() throws -> AIProviderStore {
        let defaults = try #require(UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)"))
        let connected = ProviderSettings(selectedModel: "m", lastVerified: .now)
        let settings = [AIProvider.ollama.rawValue: connected, AIProvider.openAI.rawValue: connected]
        defaults.set(try JSONEncoder().encode(settings), forKey: "AIKit.settings")
        defaults.set(AIProvider.ollama.rawValue, forKey: "AIKit.activeProvider")
        return AIProviderStore(providers: [.ollama, .openAI, .gemini], defaults: defaults)
    }

    @Test func statusShowsDefaultConnectedOrNothing() throws {
        let viewModel = ProviderListViewModel(store: try makeStore())

        #expect(viewModel.status(for: .ollama) == .defaultStatus)
        #expect(viewModel.status(for: .openAI) == .connected)
        #expect(viewModel.status(for: .gemini) == nil)
        #expect(viewModel.connectedProviders == [.ollama, .openAI])
    }

    @Test func defaultPickerIgnoresUnconnectedProviders() throws {
        let store = try makeStore()
        let viewModel = ProviderListViewModel(store: store)

        viewModel.defaultProvider = .openAI
        #expect(store.activeProvider == .openAI)

        viewModel.defaultProvider = .gemini
        #expect(store.activeProvider == .openAI)
    }
}

@MainActor
struct ModelPickerViewModelTests {
    private func makeStore() throws -> AIProviderStore {
        let defaults = try #require(UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)"))
        let settings = [AIProvider.openRouter.rawValue: ProviderSettings(
            selectedModel: "openai/gpt-x",
            availableModels: ["anthropic/claude-y", "openai/gpt-x", "openai/gpt-z"],
            lastVerified: .now
        )]
        defaults.set(try JSONEncoder().encode(settings), forKey: "AIKit.settings")
        return AIProviderStore(providers: [.openRouter], defaults: defaults)
    }

    @Test func searchFiltersAndRegroups() throws {
        let viewModel = ModelPickerViewModel(store: try makeStore(), provider: .openRouter)
        #expect(viewModel.groups.isEmpty, "Grouping waits for the view to appear")

        viewModel.regroup()
        #expect(viewModel.groups.map(\.vendor) == ["anthropic", "openai"])

        viewModel.query = "claude"

        #expect(viewModel.isSearching)
        #expect(viewModel.groups.map(\.vendor) == ["anthropic"])
    }

    @Test func choosingSelectsModel() throws {
        let store = try makeStore()
        let viewModel = ModelPickerViewModel(store: store, provider: .openRouter)
        #expect(viewModel.isSelected("openai/gpt-x"))

        viewModel.choose("openai/gpt-z")

        #expect(viewModel.isSelected("openai/gpt-z"))
        #expect(store.settings(for: .openRouter).selectedModel == "openai/gpt-z")
    }
}
