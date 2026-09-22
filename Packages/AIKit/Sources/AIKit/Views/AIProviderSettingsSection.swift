import SwiftUI

/// A single "AI Providers" row for embedding in your own settings `Form`.
/// Shows the current default provider and pushes the full provider settings.
/// Must be inside a `NavigationStack`.
///
///     Form {
///         AccountSection()
///         AIProviderSettingsSection()
///     }
public struct AIProviderSettingsSection: View {
    private let store: AIProviderStore
    private let configuration: AIKitConfiguration
    private let footer: Text?

    public init(
        store: AIProviderStore = .shared,
        configuration: AIKitConfiguration = AIKitConfiguration(),
        footer: Text? = nil
    ) {
        self.store = store
        self.configuration = configuration
        self.footer = footer
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
