import SwiftUI

/// A single "AI Providers" row for embedding in your own settings `Form`.
/// Shows the current default provider and pushes the full provider settings.
/// Must be inside a `NavigationStack`.
///
///     Form {
///         AccountSection()
///         AIProviderSettingsSection(store: providers)
///     }
public struct AIProviderSettingsSection: View {
    private let store: AIProviderStore
    private let footer: Text?

    public init(store: AIProviderStore, footer: Text? = nil) {
        self.store = store
        self.footer = footer
    }

    public var body: some View {
        Section {
            NavigationLink {
                AIProviderSettingsForm(store: store)
            } label: {
                LabeledContent {
                    Text(store.activeProvider?.displayName ?? "Not Set Up")
                } label: {
                    Label {
                        Text("AI Providers")
                    } icon: {
                        SettingsTile(symbolName: "sparkles", tint: .indigo)
                    }
                }
            }
        } footer: {
            footer
        }
    }
}

/// Settings-app style rounded icon tile.
struct SettingsTile: View {
    let symbolName: String
    let tint: Color
    @ScaledMetric private var size: CGFloat

    init(symbolName: String, tint: Color, size: CGFloat = 29) {
        self.symbolName = symbolName
        self.tint = tint
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint.gradient, in: .rect(cornerRadius: size * 0.225))
    }
}

#Preview {
    NavigationStack {
        Form {
            Section("Account") {
                Text("Signed in as Alex")
            }
            AIProviderSettingsSection(store: AIProviderStore())
        }
        .navigationTitle("Settings")
    }
}
