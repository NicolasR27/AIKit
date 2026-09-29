import SwiftUI

/// The chosen model, pushing `picker` to change it.
struct ModelSection<Destination: View>: View {
    let selectedModel: String?
    @ViewBuilder let picker: () -> Destination

    var body: some View {
        Section(.model) {
            NavigationLink(destination: picker) {
                LabeledContent(.model, value: selectedModel ?? String(localized: .none))
            }
        }
    }
}
