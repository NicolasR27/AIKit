import Foundation
import Security

/// Where API keys are kept, one per provider. Real apps use `KeychainStore`; tests swap in memory.
protocol APIKeyStorage {
    func read(_ provider: AIProvider) -> String?
    func save(_ key: String, for provider: AIProvider) throws
    func delete(_ provider: AIProvider)
}

/// Stores API keys as generic passwords in the data-protection Keychain, this device only.
struct KeychainStore: APIKeyStorage {
    var service = (Bundle.main.bundleIdentifier ?? "AIProviders") + ".api-keys"

    func read(_ provider: AIProvider) -> String? {
        var query = baseQuery(for: provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(_ key: String, for provider: AIProvider) throws {
        let data = Data(key.utf8)
        let query = baseQuery(for: provider)
        let update: [String: Any] = [kSecValueData as String: data]

        var status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(insert as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    func delete(_ provider: AIProvider) {
        SecItemDelete(baseQuery(for: provider) as CFDictionary)
    }

    private func baseQuery(for provider: AIProvider) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }
}
