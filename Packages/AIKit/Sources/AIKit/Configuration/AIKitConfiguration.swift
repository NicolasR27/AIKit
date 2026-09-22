import SwiftUI

/// Appearance and copy for AIKit's screens. Every property has a sensible default,
/// so set only what you want to change:
///
///     var config = AIKitConfiguration()
///     config.title = "Assistant"
///     config.tint = .orange
///     AIProviderSettingsView(configuration: config)
///
/// Text is `LocalizedStringResource`, so string literals are looked up in your app's
/// String Catalog and can be translated there.
public nonisolated struct AIKitConfiguration: Sendable {
    /// Navigation title of the provider list.
    public var title: LocalizedStringResource
    /// Accent for buttons, links and toggles. `nil` keeps your app's tint.
    public var tint: Color?

    /// Label of the row shown by `AIProviderSettingsSection`.
    public var rowTitle: LocalizedStringResource
    /// SF Symbol in the row's icon tile.
    public var rowSymbol: String
    /// Background of the row's icon tile.
    public var rowTint: Color

    /// Shows the "Default Provider" picker at the top of the list.
    public var showsDefaultProviderPicker: Bool
    /// Offers one-tap "Sign in with OpenRouter" on the OpenRouter page.
    public var showsOpenRouterSignIn: Bool
    /// Footer under the default provider picker. `nil` hides it.
    public var billingNote: LocalizedStringResource?
    /// Note at the bottom of the list about Keychain storage. `nil` hides it.
    public var privacyNote: LocalizedStringResource?

    public init(
        title: LocalizedStringResource = "AI Providers",
        tint: Color? = nil,
        rowTitle: LocalizedStringResource = "AI Providers",
        rowSymbol: String = "sparkles",
        rowTint: Color = .indigo,
        showsDefaultProviderPicker: Bool = true,
        showsOpenRouterSignIn: Bool = true,
        billingNote: LocalizedStringResource? = "The app sends requests to this provider using your own account. You're billed by the provider, not by us.",
        privacyNote: LocalizedStringResource? = "API keys are stored in your device's Keychain and are only sent to the provider they belong to."
    ) {
        self.title = title
        self.tint = tint
        self.rowTitle = rowTitle
        self.rowSymbol = rowSymbol
        self.rowTint = rowTint
        self.showsDefaultProviderPicker = showsDefaultProviderPicker
        self.showsOpenRouterSignIn = showsOpenRouterSignIn
        self.billingNote = billingNote
        self.privacyNote = privacyNote
    }
}

extension AIKitConfiguration {
    /// Copy with the row icon replaced where a value is given.
    func withRowIcon(_ symbol: String?, _ tint: Color?) -> AIKitConfiguration {
        var copy = self
        if let symbol { copy.rowSymbol = symbol }
        if let tint { copy.rowTint = tint }
        return copy
    }
}
