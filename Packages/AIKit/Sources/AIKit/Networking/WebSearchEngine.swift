import Foundation

/// Looks things up on the web for a model that can't search by itself (Apple Intelligence).
///
/// AIKit calls it from the on-device model's search tool, so only the search query leaves the device.
/// Set `AIProviderStore.webSearchEngine` to use your own search API (Tavily, Brave, your server…):
///
///     struct MySearch: AIWebSearchEngine {
///         func search(_ query: String) async throws -> AIAnswer {
///             // call your API, then return a short write-up of what it found + the pages
///         }
///     }
///     AIProviderStore.shared.webSearchEngine = MySearch()
public nonisolated protocol AIWebSearchEngine: Sendable {
    /// What the web says about `query`: a short summary of the findings, and the pages they came from.
    func search(_ query: String) async throws -> AIAnswer
}

/// The default engine: hands the query to another connected provider that can search (OpenAI, Claude…)
/// and passes its findings back.
nonisolated struct RelayedWebSearch: AIWebSearchEngine {
    let client: ProviderClient
    let credentials: AIProviderCredentials
    let model: String

    static let instructions = """
        You are the web search step for another assistant. Search for the query, then report what the \
        pages say in under 150 words: plain sentences with the concrete names, numbers and dates. \
        No greeting, no advice, no follow-up questions.
        """

    func search(_ query: String) async throws -> AIAnswer {
        try await client.searchWeb([.user(query)], system: Self.instructions, credentials: credentials, model: model)
    }
}
