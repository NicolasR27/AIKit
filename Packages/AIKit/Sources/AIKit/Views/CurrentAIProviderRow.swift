import SwiftUI

/// Read-only row showing which AI provider and model the app is using.
/// Updates live when the user changes their pick.
///
///     Form {
///         CurrentAIProviderRow()
///     }
public struct CurrentAIProviderRow: View {
    private let store: AIProviderStore
    private let title: LocalizedStringResource

    public init(_ title: LocalizedStringResource = "Current AI", store: AIProviderStore = .shared) {
        self.store = store
        self.title = title
    }

    public var body: some View {
        LabeledContent {
            if let provider = store.activeProvider {
                VStack(alignment: .trailing) {
                    Text(provider.displayName)
                    if let model = store.settings(for: provider).selectedModel {
                        Text(model)
                            .font(.caption)
                    }
                }
            } else {
                Text("Not Set Up")
            }
        } label: {
            Text(title)
        }
    }
}

#Preview {
    Form {
        CurrentAIProviderRow(store: AIProviderStore())
    }
}
