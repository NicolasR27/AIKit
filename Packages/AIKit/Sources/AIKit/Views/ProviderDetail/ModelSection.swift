import SwiftUI

struct ModelSection: View {
    let store: AIProviderStore
    let provider: AIProvider

    var body: some View {
        Section(.model) {
            NavigationLink {
                ModelPickerView(store: store, provider: provider)
            } label: {
                LabeledContent(.model, value: store.settings(for: provider).selectedModel ?? String(localized: .none))
            }
        }
    }
}
