import SwiftUI

/// Drop-in settings screen with its own `NavigationStack`.
/// Use it as a root view, a tab, or inside `.sheet`.
///
///     AIProviderSettingsView(store: providers)
public struct AIProviderSettingsView: View {
    private let store: AIProviderStore

    public init(store: AIProviderStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            AIProviderSettingsForm(store: store)
        }
    }
}

/// The same settings without a `NavigationStack`, for pushing from your app's own settings:
///
///     NavigationLink("AI Providers") { AIProviderSettingsForm(store: providers) }
public struct AIProviderSettingsForm: View {
    private let store: AIProviderStore

    public init(store: AIProviderStore) {
        self.store = store
    }

    public var body: some View {
        ProviderListForm()
            .environment(store)
            .navigationDestination(for: AIProvider.self) { provider in
                ProviderDetailView(provider: provider)
                    .environment(store)
            }
    }
}

private struct ProviderListForm: View {
    @Environment(AIProviderStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                Picker("Default Provider", selection: $store.activeProvider) {
                    Text("None").tag(AIProvider?.none)
                    ForEach(store.connectedProviders) { provider in
                        Text(provider.displayName).tag(Optional(provider))
                    }
                }
                .disabled(store.connectedProviders.isEmpty)
            } footer: {
                Text("The app sends requests to this provider using your own account. You're billed by the provider, not by us.")
            }

            Section("Providers") {
                ForEach(store.providers) { provider in
                    NavigationLink(value: provider) {
                        ProviderRow(provider: provider)
                    }
                }
            }

            Section {
                Label("API keys are stored in your device's Keychain and are only sent to the provider they belong to.",
                      systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI Providers")
    }
}

private struct ProviderRow: View {
    @Environment(AIProviderStore.self) private var store
    let provider: AIProvider

    var body: some View {
        LabeledContent {
            Text(status)
        } label: {
            Label {
                Text(provider.displayName)
            } icon: {
                ProviderIcon(provider: provider)
            }
        }
    }

    private var status: String {
        guard store.isConnected(provider) else { return "Not Connected" }
        return store.activeProvider == provider ? "Default" : "Connected"
    }
}

/// A provider's Settings-app style icon tile.
struct ProviderIcon: View {
    let provider: AIProvider
    var size: CGFloat = 29

    var body: some View {
        SettingsTile(symbolName: provider.symbolName, tint: provider.tint, size: size)
    }
}

extension AIProvider {
    var tint: Color {
        switch self {
        case .openAI: .black
        case .anthropic: .orange
        case .gemini: .blue
        case .mistral: .red
        case .openRouter: .purple
        case .ollama: .gray
        }
    }
}

#Preview {
    AIProviderSettingsView(store: AIProviderStore())
}
