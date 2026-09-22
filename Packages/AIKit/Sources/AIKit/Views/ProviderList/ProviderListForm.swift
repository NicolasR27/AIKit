import SwiftUI

struct ProviderListForm: View {
    @Bindable var store: AIProviderStore
    let configuration: AIKitConfiguration

    var body: some View {
        Form {
            if configuration.showsDefaultProviderPicker {
                Section {
                    Picker("Default Provider", selection: $store.activeProvider) {
                        Text("None").tag(AIProvider?.none)
                        ForEach(store.connectedProviders) { provider in
                            Text(provider.displayName).tag(Optional(provider))
                        }
                    }
                    .disabled(store.connectedProviders.isEmpty)
                } footer: {
                    if let billingNote = configuration.billingNote {
                        Text(billingNote)
                    }
                }
            }

            Section("Providers") {
                ForEach(store.providers) { provider in
                    NavigationLink {
                        ProviderDetailView(store: store, provider: provider, configuration: configuration)
                    } label: {
                        ProviderRow(store: store, provider: provider)
                    }
                }
            }

            if let privacyNote = configuration.privacyNote {
                Section {
                    Label {
                        Text(privacyNote)
                    } icon: {
                        Image(systemName: "lock.shield")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(Text(configuration.title))
        .tint(configuration.tint)
    }
}
