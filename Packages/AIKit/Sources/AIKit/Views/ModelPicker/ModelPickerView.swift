import SwiftUI

/// Searchable list, since some providers (OpenRouter) return hundreds of models.
/// OpenRouter IDs look like `anthropic/claude-…`, so they're grouped by lab.
struct ModelPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let store: AIProviderStore
    let provider: AIProvider

    @State private var query = ""
    /// Search results, grouped once per change instead of on every render.
    @State private var groups: [ModelGroup] = []

    private var settings: ProviderSettings { store.settings(for: provider) }

    var body: some View {
        List {
            ForEach(groups) { group in
                Section(group.vendor) {
                    ForEach(group.models, id: \.self) { model in
                        ModelRow(
                            title: group.displayName(for: model),
                            isSelected: settings.selectedModel == model,
                            choose: { choose(model) }
                        )
                    }
                }
            }
        }
        .overlay {
            if groups.isEmpty {
                if query.isEmpty {
                    ContentUnavailableView("No Models", systemImage: "cpu",
                                           description: Text("Test the connection again to refresh the list."))
                } else {
                    ContentUnavailableView.search
                }
            }
        }
        .searchable(text: $query, prompt: "Search models")
        .navigationTitle("Model")
        .onChange(of: query, initial: true, regroup)
        .onChange(of: settings.availableModels, regroup)
    }

    private func regroup() {
        let models = settings.availableModels
        let matches = query.isEmpty ? models : models.filter { $0.localizedStandardContains(query) }
        groups = ModelGroup.grouping(matches)
    }

    private func choose(_ model: String) {
        store.selectModel(model, for: provider)
        dismiss()
    }
}
