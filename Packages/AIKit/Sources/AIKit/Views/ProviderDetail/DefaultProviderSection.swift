import SwiftUI

struct DefaultProviderSection: View {
    let store: AIProviderStore
    let provider: AIProvider

    @State private var isDefault = false

    var body: some View {
        Section {
            Toggle("Use as Default", isOn: $isDefault)
        }
        .onAppear(perform: syncFromStore)
        .onChange(of: isDefault) { _, isOn in
            store.setDefault(provider, isOn)
        }
        .onChange(of: store.activeProvider) {
            syncFromStore()
        }
    }

    private func syncFromStore() {
        isDefault = store.isDefault(provider)
    }
}
