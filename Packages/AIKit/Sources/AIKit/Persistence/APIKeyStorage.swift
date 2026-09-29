import Foundation

/// Where API keys are kept, one per provider. Real apps use `KeychainStore`; tests swap in memory.
protocol APIKeyStorage {
    func read(_ provider: AIProvider) -> String?
    func save(_ key: String, for provider: AIProvider) throws
    func delete(_ provider: AIProvider)
}
