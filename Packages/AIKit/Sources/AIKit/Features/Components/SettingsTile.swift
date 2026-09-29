import SwiftUI

/// Settings-app style rounded icon tile that scales with Dynamic Type.
struct SettingsTile: View {
    let symbolName: String
    let tint: Color
    @ScaledMetric private var size: Double

    init(symbolName: String, tint: Color, size: Double = 29) {
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
            .accessibilityHidden(true)
    }
}
