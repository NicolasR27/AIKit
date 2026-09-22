import SwiftUI

/// Drop-in settings screen with its own `NavigationStack`.
/// Use it as a root view, a tab, or inside `.sheet`.
///
///     AIProviderSettingsView()
public struct AIProviderSettingsView: View {
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss
    private let store: AIProviderStore
    private let configuration: AIKitConfiguration

    public init(store: AIProviderStore = .shared, configuration: AIKitConfiguration = AIKitConfiguration()) {
        self.store = store
        self.configuration = configuration
    }

    public var body: some View {
        NavigationStack {
            AIProviderSettingsForm(store: store, configuration: configuration)
                .toolbar {
                    // Only when shown as a sheet/cover; as a root view or tab there's nothing to go back to.
                    if isPresented {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close", systemImage: "xmark", role: .close, action: close)
                        }
                    }
                }
        }
    }

    private func close() {
        dismiss()
    }
}

#Preview {
    AIProviderSettingsView(store: AIProviderStore())
}
