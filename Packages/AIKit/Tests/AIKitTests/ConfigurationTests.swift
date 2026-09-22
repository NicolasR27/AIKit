import SwiftUI
import Testing
@testable import AIKit

@MainActor
struct ConfigurationTests {
    @Test func rowIconOverridesOnlyWhatIsGiven() {
        let base = AIKitConfiguration(rowSymbol: "sparkles", rowTint: .indigo)

        #expect(base.withRowIcon("brain", .orange).rowSymbol == "brain")
        #expect(base.withRowIcon("brain", .orange).rowTint == .orange)
        #expect(base.withRowIcon(nil, .orange).rowSymbol == "sparkles")
        #expect(base.withRowIcon("brain", nil).rowTint == .indigo)
    }

    @Test func providerIconsFallBackToDefaults() {
        var config = AIKitConfiguration()
        config.providerIcons = [.openAI: "bolt"]
        config.providerIconColors = [.openAI: .teal]

        #expect(config.iconSymbol(for: .openAI) == "bolt")
        #expect(config.iconColor(for: .openAI) == .teal)
        #expect(config.iconSymbol(for: .anthropic) == AIProvider.anthropic.symbolName)
        #expect(config.iconColor(for: .anthropic) == AIProvider.anthropic.tint)
    }
}
