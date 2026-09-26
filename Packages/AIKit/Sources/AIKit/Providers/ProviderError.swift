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
            "Enter an API key first."
        case .invalidBaseURL:
            "That server address isn't a valid URL."
        case .invalidKey(let message):
            // Providers' own wording varies ("User not found.", "Invalid API Key"), so lead with a clear sentence.
            message.map { String(localized: "This API key was rejected (\($0)).") }
                ?? String(localized: "This API key was rejected.")
        case .server(let status, let message):
            message ?? "The provider returned HTTP \(status)."
        case .unreachable(let detail):
            "Couldn't reach the provider. \(detail)"
        case .unavailable(let reason):
            reason
        case .notAChatModel(let model):
            String(localized: "“\(model)” can't be used for chat. Choose a different model in AI provider settings.")
        case .unreadableImage:
            String(localized: "That photo couldn't be read. Try a JPEG or PNG.")
        case .imagesNotSupported(let reason):
            reason
        }
    }
}
