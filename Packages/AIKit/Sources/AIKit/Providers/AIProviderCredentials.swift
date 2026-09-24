import Foundation

/// Everything the host app needs to call a connected provider.
public nonisolated struct AIProviderCredentials: Sendable, Equatable {
    public let provider: AIProvider
    /// The model the user picked, e.g. `gpt-…`, `claude-…` or `anthropic/claude-…` on OpenRouter.
    public let model: String?
    /// `nil` for Apple Intelligence and Ollama, which don't use keys.
    public let apiKey: String?
    /// API root to build requests from; for Ollama this is the user's server address.
    /// `nil` for Apple Intelligence, which runs on the device.
    public let baseURL: URL?
}
