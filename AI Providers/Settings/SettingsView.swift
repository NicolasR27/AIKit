import SwiftUI

/// Settings-app style list of providers.
struct SettingsView: View {
    @Environment(ProviderStore.self) private var store

    var body: some View {
        @Bindable var store = store

        NavigationStack {
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
                    ForEach(AIProvider.allCases) { provider in
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
            .navigationDestination(for: AIProvider.self) { provider in
                ProviderDetailView(provider: provider)
            }
        }
    }
}

private struct ProviderRow: View {
    @Environment(ProviderStore.self) private var store
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

/// Rounded-square tile like the icons in the Settings app.
struct ProviderIcon: View {
    let provider: AIProvider
    @ScaledMetric private var size: CGFloat

    init(provider: AIProvider, size: CGFloat = 29) {
        self.provider = provider
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        Image(systemName: provider.symbolName)
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(provider.tint.gradient, in: .rect(cornerRadius: size * 0.225))
    }
}

extension AIProvider {
    var tint: Color {
        switch self {
        case .apple: .indigo
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
    SettingsView()
        .environment(ProviderStore())
}
