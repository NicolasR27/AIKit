import Foundation

/// Every provider the kit knows how to connect to.
public nonisolated enum AIProvider: String, CaseIterable, Identifiable, Codable, Sendable {
    case apple
    case openAI
    case anthropic
    case gemini
    case mistral
    case openRouter
    case ollama

    public var id: String { rawValue }

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

    public var subtitle: String {
        switch self {
        case .apple: "On-device, private, no key needed"
        case .openAI: "GPT models"
        case .anthropic: "Claude models"
        case .gemini: "Gemini models"
        case .mistral: "Mistral & Codestral models"
        case .openRouter: "Hundreds of models, one key"
        case .ollama: "Models running on your own machine"
        }
    }

    /// Default SF Symbol. Apps override it with `AIKitConfiguration.providerIcons`.
    public var symbolName: String {
        switch self {
        case .apple: "apple.intelligence"
        case .openAI: "circle.hexagongrid"
        case .anthropic: "asterisk"
        case .gemini: "sparkle"
        case .mistral: "wind"
        case .openRouter: "arrow.triangle.branch"
        case .ollama: "desktopcomputer"
        }
    }

    public var requiresAPIKey: Bool { self != .apple && self != .ollama }

    /// Runs on the device with Apple's Foundation Models framework, so it's switched on and off
    /// with a toggle and has no key, server or model list.
    var isOnDevice: Bool { self == .apple }

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

    var usesCustomBaseURL: Bool { self == .ollama }

    var defaultBaseURL: String? {
        self == .ollama ? "http://localhost:11434" : nil
    }

    var keyPlaceholder: String {
        switch self {
        case .openAI: "sk-..."
        case .anthropic: "sk-ant-..."
        case .gemini: "AIza..."
        case .openRouter: "sk-or-..."
        default: "API key"
        }
    }

    /// Where the user can create an API key.
    var keyConsoleURL: URL? {
        switch self {
        case .openAI: URL(string: "https://platform.openai.com/api-keys")
        case .anthropic: URL(string: "https://console.anthropic.com/settings/keys")
        case .gemini: URL(string: "https://aistudio.google.com/apikey")
        case .mistral: URL(string: "https://console.mistral.ai/api-keys")
        case .openRouter: URL(string: "https://openrouter.ai/keys")
        case .ollama: URL(string: "https://ollama.com/download")
        case .apple: nil
        }
    }
}
