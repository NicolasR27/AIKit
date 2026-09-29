import SwiftUI

/// Picks which connected provider the app uses, or none.
struct DefaultProviderPickerSection: View {
    let connectedProviders: [AIProvider]
    @Binding var selection: AIProvider?
    let footer: LocalizedStringResource?

    var body: some View {
        Section {
            Picker(.defaultProvider, selection: $selection) {
                Text(.none).tag(AIProvider?.none)
                ForEach(connectedProviders) { provider in
                    Text(provider.displayName).tag(Optional(provider))
                }
            }
            .disabled(connectedProviders.isEmpty)
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }
}
