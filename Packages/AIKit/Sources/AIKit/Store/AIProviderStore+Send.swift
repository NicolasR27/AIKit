import Foundation

extension AIProviderStore {
    /// Sends one prompt to the user's default provider and model and returns the reply.
    ///
    ///     let reply = try await AIProviderStore.shared.send("Summarize this: …")
    ///     let reply = try await AIProviderStore.shared.send("What watch is this?", images: [photoData])
    ///     let reply = try await AIProviderStore.shared.send("Who won last night?", webSearch: true)
    ///
    /// - Parameter webSearch: Let the provider look things up on the live web first.
    public func send(_ prompt: String, images: [Data] = [], system: String? = nil, webSearch: Bool = false) async throws -> String {
        try await send([.user(prompt, images: images)], system: system, webSearch: webSearch)
    }

    /// Sends a whole conversation (oldest first) and returns the assistant's next reply.
    /// - Parameters:
    ///   - provider: Overrides the user's default provider, if connected.
    ///   - webSearch: Let the provider look things up on the live web first.
    public func send(
        _ messages: [AIMessage],
        system: String? = nil,
        provider: AIProvider? = nil,
        webSearch: Bool = false
    ) async throws -> String {
        let (credentials, model) = try target(provider)
        if webSearch {
            return try await client.searchWeb(messages, system: system, credentials: credentials, model: model).text
        }
        return try await client.chat(messages, system: system, credentials: credentials, model: model)
    }

    /// Searches the live web, then answers, and tells you which pages it used.
    ///
    ///     let answer = try await AIProviderStore.shared.searchWeb("What's new in Swift this week?")
    ///     answer.text      // the reply
    ///     answer.sources   // [AIWebSource] — title + url, ready for Link(…)
    public func searchWeb(_ prompt: String, images: [Data] = [], system: String? = nil) async throws -> AIAnswer {
        try await searchWeb([.user(prompt, images: images)], system: system)
    }

    /// Same as `searchWeb(_:)` for a whole conversation (oldest first).
    /// - Parameter provider: Overrides the user's default provider, if connected.
    public func searchWeb(_ messages: [AIMessage], system: String? = nil, provider: AIProvider? = nil) async throws -> AIAnswer {
        let (credentials, model) = try target(provider)
        return try await client.searchWeb(messages, system: system, credentials: credentials, model: model)
    }

    /// Whether the provider `send` and `searchWeb` will use can search the web. Use it to show or hide a search switch.
    public var canSearchWeb: Bool {
        activeProvider?.supportsWebSearch == true
    }

    private func target(_ provider: AIProvider?) throws -> (AIProviderCredentials, String) {
        guard let target = provider ?? activeProvider,
              let credentials = credentials(for: target) else {
            throw AIKitError.notConnected
        }
        guard let model = credentials.model else { throw AIKitError.noModelSelected }
        return (credentials, model)
    }
}
