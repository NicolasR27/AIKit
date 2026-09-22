import SwiftUI

struct ProviderRow: View {
    let store: AIProviderStore
    let provider: AIProvider
    let configuration: AIKitConfiguration

    var body: some View {
        LabeledContent {
            Text(status)
        } label: {
            Label {
                Text(provider.displayName)
            } icon: {
                ProviderIcon(provider: provider, configuration: configuration)
            }
        }
    }

    private var status: LocalizedStringKey {
        guard store.isConnected(provider) else { return "Not Connected" }
        return store.activeProvider == provider ? "Default" : "Connected"
    }
}
