import SwiftUI

/// Shown when the list is empty: no search results, or a provider with no models.
struct ModelPickerEmptyState: View {
    let isSearching: Bool

    var body: some View {
        if isSearching {
            ContentUnavailableView.search
        } else {
            ContentUnavailableView(.noModels, systemImage: "cpu", description: Text(.noModelsDescription))
        }
    }
}
