import SwiftUI

/// A provider's Settings-app style icon tile.
struct ProviderIcon: View {
    let provider: AIProvider
    let configuration: AIKitConfiguration
    var size: Double = 29

    var body: some View {
        SettingsTile(
            symbolName: configuration.iconSymbol(for: provider),
            tint: configuration.iconColor(for: provider),
            size: size
        )
    }
}
