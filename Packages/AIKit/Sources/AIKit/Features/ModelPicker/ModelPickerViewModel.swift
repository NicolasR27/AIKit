import Foundation
import Observation

/// Search and grouping for the model list. Some providers (OpenRouter) return hundreds of models.
@Observable
final class ModelPickerViewModel {
    let provider: AIProvider
    @ObservationIgnored private let store: AIProviderStore

    var query = "" {
        didSet { regroup() }
    }
    /// Search results, grouped once per change instead of on every render.
    private(set) var groups: [ModelGroup] = []

    init(store: AIProviderStore, provider: AIProvider) {
        self.store = store
        self.provider = provider
        regroup()
    }

    var availableModels: [String] { store.settings(for: provider).availableModels }
    var selectedModel: String? { store.settings(for: provider).selectedModel }
    var isSearching: Bool { !query.isEmpty }

    func isSelected(_ model: String) -> Bool {
        selectedModel == model
    }

    func choose(_ model: String) {
        store.selectModel(model, for: provider)
    }

    /// Call when `availableModels` changes, e.g. after a re-check while the picker is open.
    func regroup() {
        let models = availableModels
        let matches = query.isEmpty ? models : models.filter { $0.localizedStandardContains(query) }
        groups = ModelGroup.grouping(matches)
    }
}
