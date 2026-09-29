import Foundation

/// Non-secret per-provider settings. API keys live in the Keychain, never here.
struct ProviderSettings: Codable, Equatable {
    var selectedModel: String?
    var availableModels: [String] = []
    var baseURL: String?
    var lastVerified: Date?
}
