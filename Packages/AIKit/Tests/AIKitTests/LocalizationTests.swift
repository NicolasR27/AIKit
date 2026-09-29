import Foundation
import Testing
@testable import AIKit

@Suite struct LocalizationTests {
    @Test(arguments: [
        ("es", "Sin configurar"),
        ("it", "Non configurato"),
        ("de", "Nicht eingerichtet"),
        ("fr", "Non configuré"),
        ("en", "Not Set Up"),
    ])
    func stringsComeFromAIKitsCatalog(language: String, expected: String) {
        var resource = LocalizedStringResource.notSetUp
        resource.locale = Locale(identifier: language)
        #expect(String(localized: resource) == expected)
    }

    @Test func interpolatedStringsKeepTheirArgument() {
        var resource = LocalizedStringResource.disconnectProvider("OpenAI")
        resource.locale = Locale(identifier: "de")
        #expect(String(localized: resource) == "OpenAI trennen?")
    }
}
