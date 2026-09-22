import Foundation
import Testing
@testable import AIKit

@MainActor
struct SelectProviderTests {
    /// A store where only Ollama is connected and active.
    private func makeStore() throws -> AIProviderStore {
        let defaults = try #require(UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)"))
        let settings = [AIProvider.ollama.rawValue: ProviderSettings(selectedModel: "m", lastVerified: .now)]
        defaults.set(try JSONEncoder().encode(settings), forKey: "AIKit.settings")
        defaults.set(AIProvider.ollama.rawValue, forKey: "AIKit.activeProvider")
        return AIProviderStore(providers: [.ollama, .openAI], defaults: defaults)
    }

    @Test func rejectsProviderThatIsNotConnected() throws {
        let store = try makeStore()

        #expect(store.selectProvider(.openAI) == false)
        #expect(store.activeProvider == .ollama)
    }

    @Test func acceptsConnectedProvider() throws {
        let store = try makeStore()
        store.activeProvider = nil

        #expect(store.selectProvider(.ollama))
        #expect(store.activeProvider == .ollama)
    }

    @Test func nilClearsDefault() throws {
        let store = try makeStore()

        #expect(store.selectProvider(nil))
        #expect(store.activeProvider == nil)
    }
}
