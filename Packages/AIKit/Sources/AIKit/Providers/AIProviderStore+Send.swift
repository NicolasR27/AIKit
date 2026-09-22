import Foundation

extension AIProviderStore {
    /// Sends one prompt to the user's default provider and model and returns the reply.
    ///
    ///     let reply = try await AIProviderStore.shared.send("Summarize this: …")
    public func send(_ prompt: String, system: String? = nil) async throws -> String {
        try await send([.user(prompt)], system: system)
    }

    /// Sends a whole conversation (oldest first) and returns the assistant's next reply.
    /// - Parameter provider: Overrides the user's default provider, if connected.
    public func send(_ messages: [AIMessage], system: String? = nil, provider: AIProvider? = nil) async throws -> String {
        guard let target = provider ?? activeProvider,
              let credentials = credentials(for: target) else {
            throw AIKitError.notConnected
        }
        guard let model = credentials.model else { throw AIKitError.noModelSelected }
        return try await client.chat(messages, system: system, credentials: credentials, model: model)
    }
}
