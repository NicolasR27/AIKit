import SwiftUI

/// Searchable list, since some providers (OpenRouter) return hundreds of models.
/// OpenRouter IDs look like `anthropic/claude-…`, so they're grouped by lab.
struct ModelPickerView: View {
    @Environment(AIProviderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let provider: AIProvider

    @State private var query = ""

    private var models: [String] {
        let all = store.settings(for: provider).availableModels
        guard !query.isEmpty else { return all }
        return all.filter { $0.localizedStandardContains(query) }
    }

    /// Groups `vendor/model` IDs by vendor; models without a slash land in one unnamed group.
    private var groups: [(vendor: String, models: [String])] {
        Dictionary(grouping: models) { $0.split(separator: "/").count > 1 ? String($0.split(separator: "/")[0]) : "" }
            .map { (vendor: $0.key, models: $0.value) }
            .sorted { $0.vendor < $1.vendor }
    }

    var body: some View {
        List {
            ForEach(groups, id: \.vendor) { group in
                Section(group.vendor) {
                    ForEach(group.models, id: \.self) { model in
                        ModelRow(model: model,
                                 title: group.vendor.isEmpty ? model : String(model.dropFirst(group.vendor.count + 1)),
                                 isSelected: store.settings(for: provider).selectedModel == model,
                                 choose: choose)
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

    private func choose(_ model: String) {
        store.selectModel(model, for: provider)
        dismiss()
    }
}

private struct ModelRow: View {
    let model: String
    let title: String
    let isSelected: Bool
    let choose: (String) -> Void

    var body: some View {
        Button {
            choose(model)
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .bold()
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
