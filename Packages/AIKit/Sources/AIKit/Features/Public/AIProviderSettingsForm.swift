import SwiftUI

/// The provider settings without a `NavigationStack`, for pushing from your app's own settings:
///
///     NavigationLink("AI Providers") { AIProviderSettingsForm() }
public struct AIProviderSettingsForm: View {
    private let configuration: AIKitConfiguration
    @State private var viewModel: ProviderListViewModel

    public init(store: AIProviderStore = .shared, configuration: AIKitConfiguration = AIKitConfiguration()) {
        _viewModel = State(initialValue: ProviderListViewModel(store: store))
        self.configuration = configuration
    }

    public var body: some View {
        // The store and configuration are passed explicitly to every screen, and links are
        // destination-based, so this works inside any host NavigationStack with no setup.
        Form {
            if configuration.showsDefaultProviderPicker {
                DefaultProviderPickerSection(
                    connectedProviders: viewModel.connectedProviders,
                    selection: $viewModel.defaultProvider,
                    footer: configuration.billingNote
                )
            }

            Section(.providers) {
                ForEach(viewModel.providers) { provider in
                    NavigationLink {
                        ProviderDetailView(store: viewModel.store, provider: provider, configuration: configuration)
                    } label: {
                        ProviderRow(provider: provider, status: viewModel.status(for: provider), configuration: configuration)
                    }
                }
            }

            if let privacyNote = configuration.privacyNote {
                PrivacyNoteSection(note: privacyNote)
            }
        }
        .navigationTitle(Text(configuration.title))
        .tint(configuration.tint)
    }
}

#Preview {
    NavigationStack {
        AIProviderSettingsForm(store: AIProviderStore())
    }
}
