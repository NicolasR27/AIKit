import Foundation

/// Errors thrown by `AIProviderStore.send`. Provider/network failures come through
/// with a user-readable `localizedDescription` as well.
public nonisolated enum AIKitError: LocalizedError, Equatable {
    /// No provider is connected, or the chosen one isn't.
    case notConnected
    /// The provider is connected but no model has been picked.
    case noModelSelected
    /// The provider answered but the reply had no text.
    case emptyResponse
    /// Web search was asked of a provider that can't do it (Ollama, or Apple Intelligence with no
    /// `webSearchEngine` and no other connected provider that can search).
    /// Check `AIProviderStore.canSearchWeb` to hide your search switch instead.
    case webSearchNotSupported(AIProvider)

    public var errorDescription: String? {
        switch self {
        case .notConnected: String(localized: .notConnectedError)
        case .noModelSelected: String(localized: .noModelSelectedError)
        case .emptyResponse: String(localized: .emptyResponseError)
        case .webSearchNotSupported(let provider): String(localized: .webSearchNotSupportedError(provider.displayName))
        }
    }
}
