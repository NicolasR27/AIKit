import SwiftUI

/// A provider's Settings-app style icon tile.
struct ProviderIcon: View {
    let provider: AIProvider
    var size: Double = 29

    var body: some View {
        SettingsTile(symbolName: provider.symbolName, tint: provider.tint, size: size)
    }
}
