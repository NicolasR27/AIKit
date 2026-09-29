import Foundation

/// Every user-facing string AIKit shows, looked up in AIKit's own String Catalog
/// (`Resources/Localizable.xcstrings`) rather than the host app's.
///
/// Use them like generated catalog symbols: `Text(.notSetUp)`, `String(localized: .missingKeyError)`.
/// Strings an app passes in through `AIKitConfiguration` still come from the app's catalog.
nonisolated extension LocalizedStringResource {
    // MARK: Defaults for public initializers (must be @usableFromInline to be default arguments)

    @usableFromInline static var aiProviders: Self { Self("AI Providers", bundle: #bundle, comment: "Title of the AI provider settings screen and the row that opens it") }
    @usableFromInline static var currentAI: Self { Self("Current AI", bundle: #bundle, comment: "Row label showing which AI provider and model the app currently uses") }
    @usableFromInline static var billingNote: Self {
        Self("The app sends requests to this provider using your own account. You're billed by the provider, not by us.", bundle: #bundle, comment: "Footer explaining that the user's own provider account is billed, not the app developer")
    }
    @usableFromInline static var privacyNote: Self {
        Self("API keys are stored in your device's Keychain and are only sent to the provider they belong to.", bundle: #bundle, comment: "Footer explaining where API keys are stored and who they are sent to")
    }

    // MARK: Provider list

    static var notSetUp: Self { Self("Not Set Up", bundle: #bundle, comment: "Shown in place of a provider name when no AI provider is chosen yet") }
    static var close: Self { Self("Close", bundle: #bundle, comment: "Button that dismisses the AI provider settings sheet") }
    static var defaultProvider: Self { Self("Default Provider", bundle: #bundle, comment: "Section title and picker label for the provider the app uses by default") }
    static var none: Self { Self("None", bundle: #bundle, comment: "Picker option meaning no default AI provider is selected") }
    static var providers: Self { Self("Providers", bundle: #bundle, comment: "Section title above the list of AI providers (OpenAI, Anthropic, …)") }
    static var notConnected: Self { Self("Not Connected", bundle: #bundle, comment: "Status next to a provider that has no API key or server saved") }
    static var defaultStatus: Self { Self("Default", bundle: #bundle, comment: "Status of the provider the app uses") }
    static var connected: Self { Self("Connected", bundle: #bundle, comment: "Status next to a provider that has a working API key or server") }

    // MARK: Provider detail

    static var apiKey: Self { Self("API Key", bundle: #bundle, comment: "Section title above the API key field") }
    static var showKey: Self { Self("Show Key", bundle: #bundle, comment: "Accessibility label for the button that reveals the typed API key") }
    static var hideKey: Self { Self("Hide Key", bundle: #bundle, comment: "Accessibility label for the button that hides the typed API key") }
    static func getAPIKey(_ provider: String) -> Self { Self("Get your \(provider) API key", bundle: #bundle, comment: "Link to the provider's website to create an API key. The argument is the provider name, e.g. OpenAI") }
    static func savedKey(_ hint: String) -> Self { Self("Saved key \(hint)", bundle: #bundle, comment: "Shows the last characters of the saved API key. The argument is like ••••a1b2") }
    static var connect: Self { Self("Connect", bundle: #bundle, comment: "Button that checks the API key or server and saves it") }
    static var testConnection: Self { Self("Test Connection", bundle: #bundle, comment: "Button that re-checks a saved API key or server") }
    static func verified(_ date: Date) -> Self {
        Self("Verified \(date, format: .relative(presentation: .named)).", bundle: #bundle, comment: "Footer saying when the connection was last checked. The argument is a relative date like yesterday or 5 minutes ago")
    }
    static var useAsDefault: Self { Self("Use as Default", bundle: #bundle, comment: "Button that makes this provider the one the app uses") }
    static var disconnect: Self { Self("Disconnect", bundle: #bundle, comment: "Destructive button that removes the saved key or server for this provider") }
    static func disconnectProvider(_ provider: String) -> Self { Self("Disconnect \(provider)?", bundle: #bundle, comment: "Confirmation dialog title. The argument is the provider name, e.g. Anthropic") }
    static var disconnectKeyMessage: Self { Self("Your saved key will be removed from this device.", bundle: #bundle, comment: "Confirmation dialog message when disconnecting a cloud provider") }
    static var disconnectServerMessage: Self {
        Self("Your saved server and model will be removed from this device.", bundle: #bundle, comment: "Confirmation dialog message when disconnecting a local Ollama server")
    }
    static var model: Self { Self("Model", bundle: #bundle, comment: "Section title and label for choosing which AI model to use") }
    static func useProvider(_ provider: String) -> Self { Self("Use \(provider)", bundle: #bundle, comment: "Toggle label to turn on an on-device provider. The argument is the provider name, e.g. Apple Intelligence") }
    static var onDeviceFooter: Self {
        Self("Runs on this device. Your requests never leave it and there's nothing to pay.", bundle: #bundle, comment: "Footer explaining that the on-device model is private and free")
    }
    static var onDeviceModel: Self { Self("On-device model", bundle: #bundle, comment: "Label for Apple's on-device language model") }
    static var server: Self { Self("Server", bundle: #bundle, comment: "Section title for the Ollama server address") }
    static var serverURL: Self { Self("Server URL", bundle: #bundle, comment: "Placeholder in the Ollama server address field") }
    static var ollamaFooter: Self {
        Self("Run Ollama on a computer on your network. From another device, use that computer's local IP address instead of localhost.", bundle: #bundle, comment: "Footer explaining how to reach an Ollama server running on another computer")
    }
    static var downloadOllama: Self { Self("Download Ollama", bundle: #bundle, comment: "Link to download the Ollama app") }

    // MARK: OpenRouter sign-in

    static var signInWithOpenRouter: Self { Self("Sign in with OpenRouter", bundle: #bundle, comment: "Button that starts signing in to OpenRouter in a browser") }
    static var signingIn: Self { Self("Signing In…", bundle: #bundle, comment: "Button title while the OpenRouter sign-in is in progress") }
    static var couldntSignIn: Self { Self("Couldn't Sign In", bundle: #bundle, comment: "Error title when OpenRouter sign-in fails") }
    static var openRouterFooter: Self {
        Self("Creates a key in your OpenRouter account automatically. Or paste an existing key below.", bundle: #bundle, comment: "Footer explaining that signing in to OpenRouter creates an API key automatically")
    }

    // MARK: Model picker

    static var noModels: Self { Self("No Models", bundle: #bundle, comment: "Empty-state title when the provider returned no models") }
    static var noModelsDescription: Self { Self("Test the connection again to refresh the list.", bundle: #bundle, comment: "Empty-state message when the provider returned no models") }
    static var searchModels: Self { Self("Search models", bundle: #bundle, comment: "Placeholder in the model search field") }

    // MARK: Provider subtitles

    static var appleSubtitle: Self { Self("On-device, private, no key needed", bundle: #bundle, comment: "Subtitle under Apple Intelligence in the provider list") }
    static var openAISubtitle: Self { Self("GPT models", bundle: #bundle, comment: "Subtitle under OpenAI in the provider list. GPT is a product name") }
    static var anthropicSubtitle: Self { Self("Claude models", bundle: #bundle, comment: "Subtitle under Anthropic in the provider list. Claude is a product name") }
    static var geminiSubtitle: Self { Self("Gemini models", bundle: #bundle, comment: "Subtitle under Google Gemini in the provider list. Gemini is a product name") }
    static var mistralSubtitle: Self { Self("Mistral & Codestral models", bundle: #bundle, comment: "Subtitle under Mistral in the provider list. Mistral and Codestral are product names") }
    static var openRouterSubtitle: Self { Self("Hundreds of models, one key", bundle: #bundle, comment: "Subtitle under OpenRouter: one key gives access to many models") }
    static var ollamaSubtitle: Self { Self("Models running on your own machine", bundle: #bundle, comment: "Subtitle under Ollama: models run on the user's own computer") }
    static var apiKeyPlaceholder: Self { Self("API key", bundle: #bundle, comment: "Placeholder in the API key field") }

    // MARK: Errors

    static var notConnectedError: Self { Self("Connect an AI provider in settings first.", bundle: #bundle, comment: "Error when the app tries to use AI before any provider is connected") }
    static var noModelSelectedError: Self { Self("Choose a model in AI provider settings first.", bundle: #bundle, comment: "Error when a provider is connected but no model is chosen") }
    static var emptyResponseError: Self { Self("The AI provider returned an empty reply.", bundle: #bundle, comment: "Error when the AI provider replied with no text") }
    static var missingKeyError: Self { Self("Enter an API key first.", bundle: #bundle, comment: "Error when Connect is tapped with an empty API key field") }
    static var invalidBaseURLError: Self { Self("That server address isn't a valid URL.", bundle: #bundle, comment: "Error when the typed server address can't be parsed") }
    static var keyRejectedError: Self { Self("This API key was rejected.", bundle: #bundle, comment: "Error when the provider refuses the API key; the one-argument form appends the provider's reason") }
    static func keyRejectedError(_ reason: String) -> Self { Self("This API key was rejected (\(reason)).", bundle: #bundle, comment: "Error when the provider refuses the API key. The argument is the provider's reason, in English") }
    static func httpError(_ status: Int) -> Self { Self("The provider returned HTTP \(status).", bundle: #bundle, comment: "Error with an HTTP status code number, e.g. 500") }
    static func unreachableError(_ detail: String) -> Self { Self("Couldn't reach the provider. \(detail)", bundle: #bundle, comment: "Error when the network request fails. The argument is the system's network error message") }
    static func notAChatModelError(_ model: String) -> Self {
        Self("“\(model)” can't be used for chat. Choose a different model in AI provider settings.", bundle: #bundle, comment: "Error when the chosen model can't chat (e.g. an embedding model). The argument is the model ID")
    }
    static var unreadableImageError: Self { Self("That photo couldn't be read. Try a JPEG or PNG.", bundle: #bundle, comment: "Error when an attached photo can't be decoded") }
    static var unexpectedResponseError: Self { Self("Unexpected response from the provider.", bundle: #bundle, comment: "Error when the provider's reply can't be understood") }
    static func keychainError(_ detail: String) -> Self { Self("Couldn't save to the Keychain (\(detail)).", bundle: #bundle, comment: "Error when the API key can't be saved securely. The argument is the system error message") }
    static var noSignInCodeError: Self {
        Self("OpenRouter didn't return a sign-in code. Please try again.", bundle: #bundle, comment: "Error when OpenRouter's sign-in page returns without a code")
    }
    static var signInFailedError: Self { Self("OpenRouter couldn't finish signing you in.", bundle: #bundle, comment: "Error when exchanging the OpenRouter sign-in code for a key fails") }

    // MARK: Apple Intelligence errors

    static var deviceNotEligibleError: Self { Self("This device doesn't support Apple Intelligence.", bundle: #bundle, comment: "Error on devices that don't support Apple Intelligence") }
    static var appleIntelligenceOffError: Self {
        Self("Turn on Apple Intelligence in Settings to use the on-device model.", bundle: #bundle, comment: "Error when Apple Intelligence is turned off in the Settings app")
    }
    static var modelNotReadyError: Self {
        Self("The on-device model is still downloading. Try again shortly.", bundle: #bundle, comment: "Error while Apple's on-device model is still downloading")
    }
    static var appleIntelligenceUnavailableError: Self {
        Self("Apple Intelligence isn't available right now.", bundle: #bundle, comment: "Generic error when Apple Intelligence can't be used")
    }
    static var mustEndWithUserError: Self { Self("The conversation must end with a user message.", bundle: #bundle, comment: "Developer-facing error: the last chat message must come from the user") }
    static var photosNotSupportedError: Self {
        Self("Apple Intelligence can't read photos on this device. Choose a cloud provider in AI provider settings.", bundle: #bundle, comment: "Error when a photo is sent to Apple Intelligence on a device without image support")
    }
}
