import Foundation
import Observation

/// Source of truth for which providers are connected and which one the app uses.
///
/// Create one at app launch, keep it in `@State`, and hand it to `AIProviderSettingsView`.
/// Read `activeCredentials` whenever you need to call the user's AI provider.
@Observable
public final class AIProviderStore {
    /// Used by every AIKit view unless you pass your own store.
    public static let shared = AIProviderStore()

    private static let settingsKey = "AIKit.settings"
    private static let activeKey = "AIKit.activeProvider"

    /// Providers shown in settings, in display order.
    public let providers: [AIProvider]

    /// The provider your app should send requests to. Users choose it in settings.
    public var activeProvider: AIProvider? {
        didSet { defaults.set(activeProvider?.rawValue, forKey: Self.activeKey) }
    }

    private(set) var settings: [String: ProviderSettings]

    /// Last four characters of each saved key, cached so views never read the Keychain while rendering.
    private var keyHints: [String: String] = [:]

    @ObservationIgnored let openRouterCallbackScheme: String
    @ObservationIgnored let openRouterKeyLabel: String
    @ObservationIgnored private let defaults: UserDefaults
    /// Internal and mutable so tests can stub the network.
    @ObservationIgnored var client = ProviderClient()

    /// - Parameters:
    ///   - providers: Which providers to offer, in display order.
    ///   - openRouterCallbackScheme: URL scheme OpenRouter redirects to after sign-in. No Info.plist entry needed.
    ///   - openRouterKeyLabel: Name shown next to the key in the user's OpenRouter dashboard.
    ///   - defaults: Where non-secret settings are saved. API keys always go to the Keychain.
    public init(
        providers: [AIProvider] = AIProvider.allCases,
        openRouterCallbackScheme: String = "aikit",
        openRouterKeyLabel: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "iOS App",
        defaults: UserDefaults = .standard
    ) {
        self.providers = providers
        self.openRouterCallbackScheme = openRouterCallbackScheme
        self.openRouterKeyLabel = openRouterKeyLabel
        self.defaults = defaults

        if let data = defaults.data(forKey: Self.settingsKey),
           let saved = try? JSONDecoder().decode([String: ProviderSettings].self, from: data) {
            settings = saved
        } else {
            settings = [:]
        }
        activeProvider = defaults.string(forKey: Self.activeKey)
            .flatMap(AIProvider.init(rawValue:))
            .flatMap { providers.contains($0) ? $0 : nil }

        for provider in providers where provider.requiresAPIKey {
            if let key = KeychainStore.read(provider.rawValue) {
                keyHints[provider.rawValue] = String(key.suffix(4))
            }
        }
    }

    // MARK: - Public API

    public var connectedProviders: [AIProvider] {
        providers.filter(isConnected)
    }

    public func isConnected(_ provider: AIProvider) -> Bool {
        settings(for: provider).lastVerified != nil
    }

    /// Credentials for the provider the user picked as default, or `nil` if nothing is connected.
    /// Reads the Keychain, so call it when you make a request rather than from a view body.
    public var activeCredentials: AIProviderCredentials? {
        activeProvider.flatMap(credentials(for:))
    }

    /// Credentials for a specific connected provider.
    public func credentials(for provider: AIProvider) -> AIProviderCredentials? {
        guard isConnected(provider) else { return nil }
        let settings = settings(for: provider)
        let baseURL = provider.usesCustomBaseURL
            ? settings.baseURL.flatMap(URL.init(string:))
            : provider.defaultAPIBaseURL
        return AIProviderCredentials(
            provider: provider,
            model: settings.selectedModel,
            apiKey: provider.requiresAPIKey ? KeychainStore.read(provider.rawValue) : nil,
            baseURL: baseURL
        )
    }

    /// Makes `provider` the default if it's connected, or clears the default when `nil`.
    /// Returns `false` and leaves `activeProvider` unchanged for a provider that isn't connected.
    @discardableResult
    public func selectProvider(_ provider: AIProvider?) -> Bool {
        if let provider, !isConnected(provider) { return false }
        activeProvider = provider
        return true
    }

    /// Removes every saved key and setting, e.g. when the user signs out of your app.
    public func disconnectAll() {
        providers.forEach(disconnect)
    }

    // MARK: - Used by the settings views

    func settings(for provider: AIProvider) -> ProviderSettings {
        settings[provider.rawValue] ?? ProviderSettings(baseURL: provider.defaultBaseURL)
    }

    func hasStoredKey(for provider: AIProvider) -> Bool {
        keyHints[provider.rawValue] != nil
    }

    /// Last four characters of the saved key, for display only.
    func maskedKey(for provider: AIProvider) -> String? {
        keyHints[provider.rawValue].map { "••••" + $0 }
    }

    /// Verifies the credentials, then saves them. Pass `nil` for `apiKey` to re-test the stored key.
    func connect(_ provider: AIProvider, apiKey: String?, baseURL: String?) async throws {
        let trimmedKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (trimmedKey?.isEmpty == false ? trimmedKey : nil) ?? KeychainStore.read(provider.rawValue)
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
        let auth = OpenRouterAuth(callbackScheme: openRouterCallbackScheme, keyLabel: openRouterKeyLabel)
        let callbackURL = try await authenticate(auth.authURL)
        let key = try await auth.exchange(callbackURL: callbackURL)
        try await connect(.openRouter, apiKey: key, baseURL: nil)
        activeProvider = .openRouter
    }

    func isDefault(_ provider: AIProvider) -> Bool {
        activeProvider == provider
    }

    func setDefault(_ provider: AIProvider, _ isOn: Bool) {
        if isOn {
            activeProvider = provider
        } else if activeProvider == provider {
            activeProvider = nil
        }
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
