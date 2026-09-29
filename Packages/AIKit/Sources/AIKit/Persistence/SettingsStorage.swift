import Foundation

/// Saves the non-secret settings (per-provider settings and the default provider) in `UserDefaults`.
/// API keys never come through here; they go to `APIKeyStorage`.
struct SettingsStorage {
    private static let settingsKey = "AIKit.settings"
    private static let activeKey = "AIKit.activeProvider"

    let defaults: UserDefaults

    func loadSettings() -> [AIProvider: ProviderSettings] {
        guard let data = defaults.data(forKey: Self.settingsKey),
              let saved = try? JSONDecoder().decode([String: ProviderSettings].self, from: data)
        else { return [:] }

        return saved.reduce(into: [:]) { result, entry in
            // Settings for a provider this version doesn't know are dropped.
            guard let provider = AIProvider(rawValue: entry.key) else { return }
            result[provider] = Self.droppingNonChatModels(entry.value, for: provider)
        }
    }

    func saveSettings(_ settings: [AIProvider: ProviderSettings]) {
        // Keyed by raw value so the saved JSON stays an object, as earlier versions wrote it.
        let byName = Dictionary(uniqueKeysWithValues: settings.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(byName) {
            defaults.set(data, forKey: Self.settingsKey)
        }
    }

    func loadActiveProvider() -> AIProvider? {
        defaults.string(forKey: Self.activeKey).flatMap(AIProvider.init(rawValue:))
    }

    func saveActiveProvider(_ provider: AIProvider?) {
        defaults.set(provider?.rawValue, forKey: Self.activeKey)
    }

    /// Lists saved before non-chat models were filtered out may still hold them,
    /// possibly as the selected model. Prune them so sends don't fail.
    private static func droppingNonChatModels(_ settings: ProviderSettings, for provider: AIProvider) -> ProviderSettings {
        var settings = settings
        settings.availableModels = ChatModels.filter(settings.availableModels, for: provider)
        if let selected = settings.selectedModel, !ChatModels.isChatModel(selected, for: provider) {
            settings.selectedModel = settings.availableModels.first
        }
        return settings
    }
}
