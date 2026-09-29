import SwiftUI

struct ProviderRow: View {
    let provider: AIProvider
    /// "Default"/"Connected", or `nil` when the provider isn't connected.
    let status: LocalizedStringResource?
    let configuration: AIKitConfiguration

    var body: some View {
        // An HStack rather than LabeledContent: LabeledContent drops the status onto its own
        // line whenever a translated subtitle is long, so rows would change shape.
        HStack {
            Label {
                // Provider names are brands and read the same in every language,
                // so the translated subtitle underneath carries the description.
                // Two Texts, not a VStack: the list styles the second as a subtitle and keeps
                // both aligned when large accessibility text wraps the label under its icon.
                Text(provider.displayName)
                Text(provider.subtitle)
            } icon: {
                ProviderIcon(provider: provider, configuration: configuration)
            }
            Spacer()
            // Only connected rows show a status, like values in the Settings app,
            // so long subtitles keep the full width on unconnected rows.
            if let status {
                Text(status)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(status == nil ? Text(.notConnected) : Text(verbatim: ""))
    }
}
