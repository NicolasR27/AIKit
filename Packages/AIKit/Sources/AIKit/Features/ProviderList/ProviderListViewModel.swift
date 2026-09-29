import Foundation
import Observation

/// State for the provider list: which providers to show, their status, and the default pick.
@Observable
final class ProviderListViewModel {
    @ObservationIgnored let store: AIProviderStore

    init(store: AIProviderStore) {
        self.store = store
    }

    var providers: [AIProvider] { store.providers }
    var connectedProviders: [AIProvider] { store.connectedProviders }

    var defaultProvider: AIProvider? {
        get { store.activeProvider }
        set { store.selectProvider(newValue) }
    }

    /// "Default" or "Connected" for connected providers; `nil` keeps unconnected rows clean.
    func status(for provider: AIProvider) -> LocalizedStringResource? {
        guard store.isConnected(provider) else { return nil }
        return store.isDefault(provider) ? .defaultStatus : .connected
    }
}
