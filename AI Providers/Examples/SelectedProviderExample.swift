import AIKit
import SwiftUI

/// How a host app reads the user's AI provider choice in code.
/// Not shown by the demo app; open the preview to try it.
struct SelectedProviderExample: View {
    @State private var selectedAIProvider: AIProvider?
    @State private var log = ""

    var body: some View {
        NavigationStack {
            Form {
                // The user picks a provider here; `selectedAIProvider` stays in sync.
                // `icon` is any SF Symbol name; `iconColor` is the tile behind it. Both optional.
                AIProviderSettingsSection(selection: $selectedAIProvider, icon: "brain", iconColor: .orange)
                CurrentAIProviderRow()

                Section("In Code") {
                    Button("Read Current Provider", action: readCurrentProvider)
                    Text(log)
                        .font(.footnote.monospaced())
                }
            }
            .navigationTitle("Settings")
            .onChange(of: selectedAIProvider) { _, provider in
                providerChanged(to: provider)
            }
        }
    }

    /// Reads the choice straight from the store; works anywhere in the app.
    private func readCurrentProvider() {
        let store = AIProviderStore.shared
        guard let provider = store.activeProvider,
              let credentials = store.activeCredentials else {
            log = "No provider connected"
            return
        }
        log = """
        provider: \(provider.displayName) (\(provider.rawValue))
        model: \(credentials.model ?? "none")
        baseURL: \(credentials.baseURL?.absoluteString ?? "none")
        """
    }

    /// Runs whenever the user switches provider, e.g. to save it or tell your backend.
    private func providerChanged(to provider: AIProvider?) {
        log = "Switched to \(provider?.displayName ?? "none")"
    }
}

#Preview {
    SelectedProviderExample()
}
