import SwiftUI

extension AIProvider {
    /// Icon tile color. Avoids black/white so tiles stay visible in both light and dark mode.
    var tint: Color {
        switch self {
        case .openAI: .green
        case .anthropic: .orange
        case .gemini: .blue
        case .mistral: .red
        case .openRouter: .purple
        case .ollama: .gray
        }
    }
}
