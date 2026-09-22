import Foundation
import Observation

/// Source of truth for which providers are connected and which one the app uses.
@Observable
final class ProviderStore {
    private static let settingsKey = "providerSettings"
    private static let activeKey = "activeProvider"

    private(set) var settings: [String: ProviderSettings]

    /// Last four characters of each saved key, cached so views never read the Keychain while rendering.
    private var keyHints: [String: String] = [:]

    var activeProvider: AIProvider? {
        didSet { defaults.set(activeProvider?.rawValue, forKey: Self.activeKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let client: ProviderClient

    init(defaults: UserDefaults = .standard, client: ProviderClient = ProviderClient()) {
        self.defaults = defaults
        self.client = client

        if let data = defaults.data(forKey: Self.settingsKey),
           let saved = try? JSONDecoder().decode([String: ProviderSettings].self, from: data) {
            settings = saved
        } else {
            settings = [:]
        }
        activeProvider = defaults.string(forKey: Self.activeKey).flatMap(AIProvider.init(rawValue:))

        for provider in AIProvider.allCases where provider.requiresAPIKey {
            if let key = KeychainStore.read(provider.rawValue) {
                keyHints[provider.rawValue] = String(key.suffix(4))
            }
        }
    }

    // MARK: - Queries

    func settings(for provider: AIProvider) -> ProviderSettings {
        settings[provider.rawValue] ?? ProviderSettings(baseURL: provider.defaultBaseURL)
    }

    func isConnected(_ provider: AIProvider) -> Bool {
        settings(for: provider).lastVerified != nil
    }

    var connectedProviders: [AIProvider] {
        AIProvider.allCases.filter(isConnected)
    }

    func hasStoredKey(for provider: AIProvider) -> Bool {
        keyHints[provider.rawValue] != nil
    }

    /// Last four characters of the saved key, for display only.
    func maskedKey(for provider: AIProvider) -> String? {
        keyHints[provider.rawValue].map { "••••" + $0 }
    }

    /// Reads the Keychain; call when making a request, not from a view body.
    func storedKey(for provider: AIProvider) -> String? {
        KeychainStore.read(provider.rawValue)
    }

    // MARK: - Mutations

    /// Verifies the credentials, then saves them. Pass `nil` for `apiKey` to re-test the stored key.
    func connect(_ provider: AIProvider, apiKey: String?, baseURL: String?) async throws {
        let trimmedKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (trimmedKey?.isEmpty == false ? trimmedKey : nil) ?? storedKey(for: provider)
        let url = baseURL?.trimmingCharacters(in: .whitespacesAndNewlines)

        let models = try await client.fetchModels(for: provider, apiKey: key, baseURL: url)
        // The user left the screen mid-check; don't save credentials they walked away from.
        try Task.checkCancellation()

        if provider.requiresAPIKey, let key {
            try KeychainStore.save(key, for: provider.rawValue)
            keyHints[provider.rawValue] = String(key.suffix(4))
        }

        var updated = settings(for: provider)
        updated.availableModels = models
        updated.lastVerified = .now
        if provider.usesCustomBaseURL {
            updated.baseURL = url?.isEmpty == false ? url : provider.defaultBaseURL
        }
        if updated.selectedModel.map(models.contains) != true {
            updated.selectedModel = models.first
        }
        update(provider, updated)

        if activeProvider == nil {
            activeProvider = provider
        }
    }

    /// Runs OpenRouter's OAuth flow. `authenticate` presents the web sheet and returns the callback URL.
    func signInWithOpenRouter(authenticate: (URL) async throws -> URL) async throws {
        let auth = OpenRouterAuth()
        let callbackURL = try await authenticate(auth.authURL)
        let key = try await auth.exchange(callbackURL: callbackURL)
        try await connect(.openRouter, apiKey: key, baseURL: nil)
        activeProvider = .openRouter
    }

    func selectModel(_ model: String, for provider: AIProvider) {
        var updated = settings(for: provider)
        updated.selectedModel = model
        update(provider, updated)
    }

    func disconnect(_ provider: AIProvider) {
        KeychainStore.delete(provider.rawValue)
        keyHints[provider.rawValue] = nil
        settings[provider.rawValue] = nil
        persist()
        if activeProvider == provider {
            activeProvider = connectedProviders.first
        }
    }

    private func update(_ provider: AIProvider, _ value: ProviderSettings) {
        settings[provider.rawValue] = value
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.settingsKey)
        }
    }
}
