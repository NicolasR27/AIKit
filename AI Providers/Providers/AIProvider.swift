import Foundation

/// Every provider the app knows how to connect to.
enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case apple
    case openAI
    case anthropic
    case gemini
    case mistral
    case openRouter
    case ollama

    var id: String { rawValue }

    var displayName: String {
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

    var subtitle: String {
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

    var symbolName: String {
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

    var requiresAPIKey: Bool {
        switch self {
        case .apple, .ollama: false
        default: true
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

/// Non-secret per-provider settings. API keys live in the Keychain, never here.
struct ProviderSettings: Codable, Equatable {
    var selectedModel: String?
    var availableModels: [String] = []
    var baseURL: String?
    var lastVerified: Date?
}
