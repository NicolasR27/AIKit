import SwiftUI

struct ModelSection: View {
    let store: AIProviderStore
    let provider: AIProvider

    var body: some View {
        Section("Model") {
            NavigationLink {
                ModelPickerView(store: store, provider: provider)
            } label: {
                LabeledContent("Model", value: store.settings(for: provider).selectedModel ?? String(localized: "None"))
            }
        }
    }
}
