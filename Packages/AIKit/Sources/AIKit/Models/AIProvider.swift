import Foundation

/// Every provider the kit knows how to connect to.
///
/// Display details (subtitle, icon, key console link) live in `AIProvider+Presentation.swift`.
public nonisolated enum AIProvider: String, CaseIterable, Identifiable, Codable, Sendable {
    case apple
    case openAI
    case anthropic
    case gemini
    case mistral
    case openRouter
    case ollama

    public var id: String { rawValue }

    /// Brand name; reads the same in every language.
    public var displayName: String {
        switch self {
        case .apple: "Apple Intelligence"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Google Gemini"
        case .mistral: "Mistral"
        case .openRouter: "OpenRouter"
        case .ollama: "Ollama"
        }
    }

    public var requiresAPIKey: Bool { self != .apple && self != .ollama }

    /// Runs on the device with Apple's Foundation Models framework, so it's switched on and off
    /// with a toggle and has no key, server or model list.
    var isOnDevice: Bool { self == .apple }

    /// Self-hosted: the user types the server address.
    var usesCustomBaseURL: Bool { self == .ollama }

    /// Root of the provider's REST API, for building your own requests.
    /// For Ollama, `AIProviderCredentials.baseURL` carries the user's server address instead.
    /// `nil` for Apple Intelligence, which runs on the device.
    public var defaultAPIBaseURL: URL? {
        switch self {
        case .apple: nil
        case .openAI: URL(string: "https://api.openai.com/v1")
        case .anthropic: URL(string: "https://api.anthropic.com/v1")
        case .gemini: URL(string: "https://generativelanguage.googleapis.com/v1beta")
        case .mistral: URL(string: "https://api.mistral.ai/v1")
        case .openRouter: URL(string: "https://openrouter.ai/api/v1")
        case .ollama: URL(string: "http://localhost:11434")
        }
    }

    /// Pre-filled server address for providers that use a custom base URL.
    var defaultBaseURL: String? {
        usesCustomBaseURL ? defaultAPIBaseURL?.absoluteString : nil
    }
}
