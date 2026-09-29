import Foundation

/// Every user-facing string AIKit shows, looked up in AIKit's own String Catalog
/// (`Resources/Localizable.xcstrings`) rather than the host app's.
///
/// Use them like generated catalog symbols: `Text(.notSetUp)`, `String(localized: .missingKeyError)`.
/// Strings an app passes in through `AIKitConfiguration` still come from the app's catalog.
nonisolated extension LocalizedStringResource {
    // MARK: Defaults for public initializers (must be @usableFromInline to be default arguments)

    @usableFromInline static var aiProviders: Self { Self("AI Providers", bundle: #bundle) }
    @usableFromInline static var currentAI: Self { Self("Current AI", bundle: #bundle) }
    @usableFromInline static var billingNote: Self {
        Self("The app sends requests to this provider using your own account. You're billed by the provider, not by us.", bundle: #bundle)
    }
    @usableFromInline static var privacyNote: Self {
        Self("API keys are stored in your device's Keychain and are only sent to the provider they belong to.", bundle: #bundle)
    }

    // MARK: Provider list

    static var notSetUp: Self { Self("Not Set Up", bundle: #bundle) }
    static var close: Self { Self("Close", bundle: #bundle) }
    static var defaultProvider: Self { Self("Default Provider", bundle: #bundle) }
    static var none: Self { Self("None", bundle: #bundle) }
    static var providers: Self { Self("Providers", bundle: #bundle) }
    static var notConnected: Self { Self("Not Connected", bundle: #bundle) }
    static var defaultStatus: Self { Self("Default", bundle: #bundle, comment: "Status of the provider the app uses") }
    static var connected: Self { Self("Connected", bundle: #bundle) }

    // MARK: Provider detail

    static var apiKey: Self { Self("API Key", bundle: #bundle) }
    static var showKey: Self { Self("Show Key", bundle: #bundle) }
    static var hideKey: Self { Self("Hide Key", bundle: #bundle) }
    static func getAPIKey(_ provider: String) -> Self { Self("Get your \(provider) API key", bundle: #bundle) }
    static func savedKey(_ hint: String) -> Self { Self("Saved key \(hint)", bundle: #bundle) }
    static var connect: Self { Self("Connect", bundle: #bundle) }
    static var testConnection: Self { Self("Test Connection", bundle: #bundle) }
    static func verified(_ date: Date) -> Self {
        Self("Verified \(date, format: .relative(presentation: .named)).", bundle: #bundle)
    }
    static var useAsDefault: Self { Self("Use as Default", bundle: #bundle) }
    static var disconnect: Self { Self("Disconnect", bundle: #bundle) }
    static func disconnectProvider(_ provider: String) -> Self { Self("Disconnect \(provider)?", bundle: #bundle) }
    static var disconnectKeyMessage: Self { Self("Your saved key will be removed from this device.", bundle: #bundle) }
    static var disconnectServerMessage: Self {
        Self("Your saved server and model will be removed from this device.", bundle: #bundle)
    }
    static var model: Self { Self("Model", bundle: #bundle) }
    static func useProvider(_ provider: String) -> Self { Self("Use \(provider)", bundle: #bundle) }
    static var onDeviceFooter: Self {
        Self("Runs on this device. Your requests never leave it and there's nothing to pay.", bundle: #bundle)
    }
    static var onDeviceModel: Self { Self("On-device model", bundle: #bundle) }
    static var server: Self { Self("Server", bundle: #bundle) }
    static var serverURL: Self { Self("Server URL", bundle: #bundle) }
    static var ollamaFooter: Self {
        Self("Run Ollama on a computer on your network. From another device, use that computer's local IP address instead of localhost.", bundle: #bundle)
    }
    static var downloadOllama: Self { Self("Download Ollama", bundle: #bundle) }

    // MARK: OpenRouter sign-in

    static var signInWithOpenRouter: Self { Self("Sign in with OpenRouter", bundle: #bundle) }
    static var signingIn: Self { Self("Signing In…", bundle: #bundle) }
    static var couldntSignIn: Self { Self("Couldn't Sign In", bundle: #bundle) }
    static var openRouterFooter: Self {
        Self("Creates a key in your OpenRouter account automatically. Or paste an existing key below.", bundle: #bundle)
    }

    // MARK: Model picker

    static var noModels: Self { Self("No Models", bundle: #bundle) }
    static var noModelsDescription: Self { Self("Test the connection again to refresh the list.", bundle: #bundle) }
    static var searchModels: Self { Self("Search models", bundle: #bundle) }

    // MARK: Provider subtitles

    static var appleSubtitle: Self { Self("On-device, private, no key needed", bundle: #bundle) }
    static var openAISubtitle: Self { Self("GPT models", bundle: #bundle) }
    static var anthropicSubtitle: Self { Self("Claude models", bundle: #bundle) }
    static var geminiSubtitle: Self { Self("Gemini models", bundle: #bundle) }
    static var mistralSubtitle: Self { Self("Mistral & Codestral models", bundle: #bundle) }
    static var openRouterSubtitle: Self { Self("Hundreds of models, one key", bundle: #bundle) }
    static var ollamaSubtitle: Self { Self("Models running on your own machine", bundle: #bundle) }
    static var apiKeyPlaceholder: Self { Self("API key", bundle: #bundle, comment: "Placeholder in the API key field") }

    // MARK: Errors

    static var notConnectedError: Self { Self("Connect an AI provider in settings first.", bundle: #bundle) }
    static var noModelSelectedError: Self { Self("Choose a model in AI provider settings first.", bundle: #bundle) }
    static var emptyResponseError: Self { Self("The AI provider returned an empty reply.", bundle: #bundle) }
    static var missingKeyError: Self { Self("Enter an API key first.", bundle: #bundle) }
    static var invalidBaseURLError: Self { Self("That server address isn't a valid URL.", bundle: #bundle) }
    static var keyRejectedError: Self { Self("This API key was rejected.", bundle: #bundle) }
    static func keyRejectedError(_ reason: String) -> Self { Self("This API key was rejected (\(reason)).", bundle: #bundle) }
    static func httpError(_ status: Int) -> Self { Self("The provider returned HTTP \(status).", bundle: #bundle) }
    static func unreachableError(_ detail: String) -> Self { Self("Couldn't reach the provider. \(detail)", bundle: #bundle) }
    static func notAChatModelError(_ model: String) -> Self {
        Self("“\(model)” can't be used for chat. Choose a different model in AI provider settings.", bundle: #bundle)
    }
    static var unreadableImageError: Self { Self("That photo couldn't be read. Try a JPEG or PNG.", bundle: #bundle) }
    static var unexpectedResponseError: Self { Self("Unexpected response from the provider.", bundle: #bundle) }
    static func keychainError(_ detail: String) -> Self { Self("Couldn't save to the Keychain (\(detail)).", bundle: #bundle) }
    static var noSignInCodeError: Self {
        Self("OpenRouter didn't return a sign-in code. Please try again.", bundle: #bundle)
    }
    static var signInFailedError: Self { Self("OpenRouter couldn't finish signing you in.", bundle: #bundle) }

    // MARK: Apple Intelligence errors

    static var deviceNotEligibleError: Self { Self("This device doesn't support Apple Intelligence.", bundle: #bundle) }
    static var appleIntelligenceOffError: Self {
        Self("Turn on Apple Intelligence in Settings to use the on-device model.", bundle: #bundle)
    }
    static var modelNotReadyError: Self {
        Self("The on-device model is still downloading. Try again shortly.", bundle: #bundle)
    }
    static var appleIntelligenceUnavailableError: Self {
        Self("Apple Intelligence isn't available right now.", bundle: #bundle)
    }
    static var mustEndWithUserError: Self { Self("The conversation must end with a user message.", bundle: #bundle) }
    static var photosNotSupportedError: Self {
        Self("Apple Intelligence can't read photos on this device. Choose a cloud provider in AI provider settings.", bundle: #bundle)
    }
}
