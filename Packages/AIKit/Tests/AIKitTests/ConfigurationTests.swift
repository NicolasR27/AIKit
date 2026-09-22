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
}
