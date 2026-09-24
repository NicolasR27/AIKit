import SwiftUI

extension AIProvider {
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
}
