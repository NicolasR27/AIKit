import SwiftUI

/// Searchable list, since some providers (OpenRouter) return hundreds of models.
/// OpenRouter IDs look like `anthropic/claude-…`, so they're grouped by lab.
struct ModelPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let store: AIProviderStore
    let provider: AIProvider

    @State private var query = ""

    var body: some View {
        let settings = store.settings(for: provider)
        let models = filtered(settings.availableModels)

        List {
            ForEach(ModelGroup.grouping(models)) { group in
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
            if models.isEmpty {
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
    }

    private func filtered(_ models: [String]) -> [String] {
        guard !query.isEmpty else { return models }
        return models.filter { $0.localizedStandardContains(query) }
    }

    private func choose(_ model: String) {
        store.selectModel(model, for: provider)
        dismiss()
    }
}
