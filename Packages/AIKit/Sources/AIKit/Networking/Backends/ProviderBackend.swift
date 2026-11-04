import Foundation

/// One provider's API: verifying credentials by listing models, and chatting.
///
/// A backend is built per call with everything it needs already checked (a usable base URL,
/// a non-empty key when the provider requires one), so implementations only speak their wire format.
protocol ProviderBackend {
    /// The chat models this key can use. A successful list doubles as proof the key works.
    func models() async throws -> [String]
    /// The assistant's reply to `messages` (oldest first). May be empty; the caller rejects that.
    func reply(to messages: [AIMessage], system: String?, model: String) async throws -> String
    /// Like `reply`, but the provider's own web search tool runs first. Only called for providers
    /// whose `supportsWebSearch` is true.
    func searchWeb(_ messages: [AIMessage], system: String?, model: String) async throws -> AIAnswer
}

extension ProviderBackend {
    func searchWeb(_ messages: [AIMessage], system: String?, model: String) async throws -> AIAnswer {
        preconditionFailure("\(Self.self) has no web search; ProviderClient checks supportsWebSearch first.")
    }
}
