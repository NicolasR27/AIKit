import SwiftUI

/// The provider settings without a `NavigationStack`, for pushing from your app's own settings:
///
///     NavigationLink("AI Providers") { AIProviderSettingsForm() }
public struct AIProviderSettingsForm: View {
    private let store: AIProviderStore
    private let configuration: AIKitConfiguration

    public init(store: AIProviderStore = .shared, configuration: AIKitConfiguration = AIKitConfiguration()) {
        self.store = store
        self.configuration = configuration
    }

    public var body: some View {
        // The store and configuration are passed explicitly to every screen, and links are
        // destination-based, so this works inside any host NavigationStack with no setup.
        ProviderListForm(store: store, configuration: configuration)
    }
}
