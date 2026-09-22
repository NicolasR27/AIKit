import SwiftUI

/// A single "AI Providers" row for embedding in your own settings `Form`.
/// Shows the current default provider and pushes the full provider settings.
/// Must be inside a `NavigationStack`.
///
///     Form {
///         AccountSection()
///         AIProviderSettingsSection()
///     }
///
/// Pass `selection` to mirror the user's default provider into your own state:
///
///     @State private var selectedAIProvider: AIProvider?
///     AIProviderSettingsSection(selection: $selectedAIProvider)
public struct AIProviderSettingsSection: View {
    private let store: AIProviderStore
    private let configuration: AIKitConfiguration
    private let footer: Text?
    private let selection: Binding<AIProvider?>?

    public init(
        store: AIProviderStore = .shared,
        configuration: AIKitConfiguration = AIKitConfiguration(),
        footer: Text? = nil
    ) {
        self.store = store
        self.configuration = configuration
        self.footer = footer
        self.selection = nil
    }

    /// - Parameter selection: Kept in sync with `store.activeProvider` both ways.
    ///   Setting it to a provider that isn't connected is ignored and snaps back.
    public init(
        selection: Binding<AIProvider?>,
        store: AIProviderStore = .shared,
        configuration: AIKitConfiguration = AIKitConfiguration(),
        footer: Text? = nil
    ) {
        self.store = store
        self.configuration = configuration
        self.footer = footer
        self.selection = selection
    }

    public var body: some View {
        Section {
            NavigationLink {
                AIProviderSettingsForm(store: store, configuration: configuration)
            } label: {
                LabeledContent {
                    Text(store.activeProvider?.displayName ?? String(localized: "Not Set Up"))
                } label: {
                    Label {
                        Text(configuration.rowTitle)
                    } icon: {
                        SettingsTile(symbolName: configuration.rowSymbol, tint: configuration.rowTint)
                    }
                }
            }
        } footer: {
            footer
        }
        .onChange(of: store.activeProvider, initial: true) { _, provider in
            if selection?.wrappedValue != provider {
                selection?.wrappedValue = provider
            }
        }
        .onChange(of: selection?.wrappedValue) { _, provider in
            selectionChanged(to: provider)
        }
    }

    private func selectionChanged(to provider: AIProvider?) {
        guard let selection, provider != store.activeProvider else { return }
        if !store.selectProvider(provider) {
            selection.wrappedValue = store.activeProvider
        }
    }
}

#Preview("Selection binding") {
    @Previewable @State var selectedAIProvider: AIProvider?

    NavigationStack {
        Form {
            AIProviderSettingsSection(selection: $selectedAIProvider, store: AIProviderStore())
            LabeledContent("Selected", value: selectedAIProvider?.displayName ?? "None")
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        Form {
            Section("Account") {
                Text("Signed in as Alex")
            }
            AIProviderSettingsSection(store: AIProviderStore())
        }
        .navigationTitle("Settings")
    }
}
