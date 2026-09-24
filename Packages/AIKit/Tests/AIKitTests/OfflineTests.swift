import CryptoKit
import Foundation
import Testing
@testable import AIKit

@MainActor
struct OpenRouterAuthURLTests {
    @Test func authURLCarriesPKCEParameters() throws {
        let auth = OpenRouterAuth(callbackScheme: "myapp", keyLabel: "My App")
        let items = try #require(URLComponents(url: auth.authURL, resolvingAgainstBaseURL: false)?.queryItems)
        let query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })

        #expect(auth.authURL.host == "openrouter.ai")
        #expect(query["callback_url"] == "myapp://oauth/openrouter")
        #expect(query["code_challenge_method"] == "S256")
        #expect(query["key_label"] == "My App")

        // Challenge must be base64url(SHA256(verifier)) with no padding.
        let expected = Data(SHA256.hash(data: Data(auth.codeVerifier.utf8))).base64EncodedString()
            .replacing("+", with: "-").replacing("/", with: "_").replacing("=", with: "")
        #expect(query["code_challenge"] == expected)
    }

    @Test func verifierIsURLSafeAndUnique() {
        let first = OpenRouterAuth(callbackScheme: "a", keyLabel: "b").codeVerifier
        let second = OpenRouterAuth(callbackScheme: "a", keyLabel: "b").codeVerifier

        #expect(first != second)
        #expect(first.count >= 43)
        #expect(!first.contains { "+/=".contains($0) })
    }
}

@MainActor
struct ModelGroupTests {
    @Test func groupsByVendorPrefixAndSortsVendors() {
        let groups = ModelGroup.grouping(["openai/gpt-x", "anthropic/claude-y", "openai/gpt-z"])

        #expect(groups.map(\.vendor) == ["anthropic", "openai"])
        #expect(groups[1].models == ["openai/gpt-x", "openai/gpt-z"])
        #expect(groups[1].displayName(for: "openai/gpt-x") == "gpt-x")
    }

    @Test func idsWithoutSlashShareUnnamedGroup() {
        let groups = ModelGroup.grouping(["gpt-a", "gpt-b"])

        #expect(groups.count == 1)
        #expect(groups[0].vendor.isEmpty)
        #expect(groups[0].displayName(for: "gpt-a") == "gpt-a")
    }
}

@MainActor
struct AppleIntelligenceTests {
    @Test func needsNoKeyOrServer() {
        #expect(AIProvider.apple.isOnDevice)
        #expect(!AIProvider.apple.requiresAPIKey)
        #expect(AIProvider.apple.defaultAPIBaseURL == nil)
    }

    @Test func savedSettingsGiveKeylessCredentials() throws {
        let defaults = UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!
        let settings = [AIProvider.apple.rawValue: ProviderSettings(selectedModel: AppleIntelligence.modelName, lastVerified: .now)]
        defaults.set(try JSONEncoder().encode(settings), forKey: "AIKit.settings")
        let store = AIProviderStore(providers: [.apple], defaults: defaults)

        let credentials = try #require(store.credentials(for: .apple))
        #expect(credentials.model == AppleIntelligence.modelName)
        #expect(credentials.apiKey == nil)
        #expect(credentials.baseURL == nil)
    }
}
