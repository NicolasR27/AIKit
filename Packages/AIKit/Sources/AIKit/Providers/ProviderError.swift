import Foundation

enum ProviderError: LocalizedError {
    case missingKey
    case invalidBaseURL
    case invalidKey(String?)
    case server(status: Int, message: String?)
    case unreachable(String)
    case unavailable(String)
    case notAChatModel(String)
    case unreadableImage
    case imagesNotSupported(String)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            String(localized: .missingKeyError)
        case .invalidBaseURL:
            String(localized: .invalidBaseURLError)
        case .invalidKey(let message):
            // Providers' own wording varies ("User not found.", "Invalid API Key"), so lead with a clear sentence.
            message.map { String(localized: .keyRejectedError($0)) } ?? String(localized: .keyRejectedError)
        case .server(let status, let message):
            message ?? String(localized: .httpError(status))
        case .unreachable(let detail):
            String(localized: .unreachableError(detail))
        case .unavailable(let reason):
            reason
        case .notAChatModel(let model):
            String(localized: .notAChatModelError(model))
        case .unreadableImage:
            String(localized: .unreadableImageError)
        case .imagesNotSupported(let reason):
            reason
        }
    }
}
