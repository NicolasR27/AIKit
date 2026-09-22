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

    public var errorDescription: String? {
        switch self {
        case .notConnected: String(localized: "Connect an AI provider in settings first.")
        case .noModelSelected: String(localized: "Choose a model in AI provider settings first.")
        case .emptyResponse: String(localized: "The AI provider returned an empty reply.")
        }
    }
}
