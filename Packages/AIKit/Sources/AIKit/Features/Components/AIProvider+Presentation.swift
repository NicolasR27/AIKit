import SwiftUI

/// How each provider looks and reads in AIKit's screens.
/// `nonisolated` like the enum itself, so apps can read these off the main actor.
nonisolated extension AIProvider {
    public var subtitle: String {
        switch self {
        case .apple: String(localized: .appleSubtitle)
        case .openAI: String(localized: .openAISubtitle)
        case .anthropic: String(localized: .anthropicSubtitle)
        case .gemini: String(localized: .geminiSubtitle)
        case .mistral: String(localized: .mistralSubtitle)
        case .openRouter: String(localized: .openRouterSubtitle)
        case .ollama: String(localized: .ollamaSubtitle)
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

    /// Default icon tile color. Apps override it with `AIKitConfiguration.providerIconColors`.
    /// Avoids black/white so tiles stay visible in both light and dark mode.
    var tint: Color {
        switch self {
        case .apple: .indigo
        case .openAI: .green
        case .anthropic: .orange
        case .gemini: .blue
        case .mistral: .red
        case .openRouter: .purple
        case .ollama: .gray
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .openAI: "sk-..."
        case .anthropic: "sk-ant-..."
        case .gemini: "AIza..."
        case .openRouter: "sk-or-..."
        default: String(localized: .apiKeyPlaceholder)
        }
    }

    /// Where the user can create an API key (or, for Ollama, download the server).
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

    /// The name to show for a model ID. The on-device model's ID is an English
    /// placeholder, so it's replaced with a translated name.
    func displayName(forModel model: String) -> String {
        isOnDevice ? String(localized: .onDeviceModel) : model
    }
}
