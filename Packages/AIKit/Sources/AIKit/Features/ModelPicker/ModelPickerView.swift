import SwiftUI

/// Searchable list of the provider's models.
/// OpenRouter IDs look like `anthropic/claude-…`, so they're grouped by lab.
struct ModelPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ModelPickerViewModel

    init(viewModel: ModelPickerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.groups) { group in
                Section(group.vendor) {
                    ForEach(group.models, id: \.self) { model in
                        ModelRow(
                            title: group.displayName(for: model),
                            isSelected: viewModel.isSelected(model),
                            choose: { choose(model) }
                        )
                    }
                }
            }
        }
        .overlay {
            if viewModel.groups.isEmpty {
                ModelPickerEmptyState(isSearching: viewModel.isSearching)
            }
        }
        .searchable(text: $viewModel.query, prompt: .searchModels)
        .navigationTitle(.model)
        .onChange(of: viewModel.availableModels, initial: true) {
            viewModel.regroup()
        }
    }

    private func choose(_ model: String) {
        viewModel.choose(model)
        dismiss()
    }
}
