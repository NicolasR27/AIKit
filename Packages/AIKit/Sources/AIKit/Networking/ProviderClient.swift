import Foundation

/// Routes each request to the right `ProviderBackend`, and owns the checks and error
/// mapping every provider shares.
struct ProviderClient {
    var session: URLSession = .shared

    /// Verifies credentials by listing the models they can access.
    /// - Parameter baseURL: The server address the user typed; only used by self-hosted providers.
    func fetchModels(for provider: AIProvider, apiKey: String?, baseURL: String?) async throws -> [String] {
        let base = provider.usesCustomBaseURL
            ? try Self.serverURL(from: baseURL, default: provider.defaultBaseURL)
            : provider.defaultAPIBaseURL
        return try await backend(for: provider, apiKey: apiKey, baseURL: base).models()
    }

    /// Sends a conversation to the provider's chat endpoint and returns the reply text.
    func chat(
        _ messages: [AIMessage],
        system: String?,
        credentials: AIProviderCredentials,
        model: String
    ) async throws -> String {
        let backend = try backend(for: credentials.provider, apiKey: credentials.apiKey, baseURL: credentials.baseURL)
        let reply: String
        do {
            reply = try await backend.reply(to: messages, system: system, model: model)
        } catch ProviderError.server(_, let message?) where Self.isNotAChatModelMessage(message) {
            throw ProviderError.notAChatModel(model)
        }
        guard !reply.isEmpty else { throw AIKitError.emptyResponse }
        return reply
    }

    /// Same as `chat`, but the provider searches and reads the live web first and reports its sources.
    func searchWeb(
        _ messages: [AIMessage],
        system: String?,
        credentials: AIProviderCredentials,
        model: String
    ) async throws -> AIAnswer {
        guard credentials.provider.supportsWebSearch else {
            throw AIKitError.webSearchNotSupported(credentials.provider)
        }
        let backend = try backend(for: credentials.provider, apiKey: credentials.apiKey, baseURL: credentials.baseURL)
        let answer: AIAnswer
        do {
            answer = try await backend.searchWeb(messages, system: Self.steered(system), model: model)
        } catch ProviderError.server(_, let message?) where Self.isNotAChatModelMessage(message) {
            throw ProviderError.notAChatModel(model)
        }
        guard !answer.text.isEmpty else { throw AIKitError.emptyResponse }
        return answer
    }

    // MARK: - Web search steering

    /// Every provider lets the model decide whether to actually run the search it was given, and a
    /// model that skips it answers from memory and hedges ("unverified", "no live web access").
    /// This goes ahead of the host's system prompt so the model searches, reads and cites instead.
    static let webSearchDirective = """
        Live web search and page reading tools are enabled for this request. Use them before you answer: \
        search for anything current, specific or checkable (facts, names, numbers, dates, prices, products, \
        people, organizations), open the pages you rely on, and cite them. Never say you lack web access or \
        that the answer was prepared without live retrieval. Mark a claim as unverified only after a search \
        found nothing relevant.
        """

    static func steered(_ system: String?) -> String {
        guard let system, !system.isEmpty else { return webSearchDirective }
        return webSearchDirective + "\n\n" + system
    }

    // MARK: - Routing

    private func backend(for provider: AIProvider, apiKey: String?, baseURL: URL?) throws -> any ProviderBackend {
        if provider.isOnDevice { return AppleIntelligenceBackend() }

        guard let baseURL else { throw ProviderError.invalidBaseURL }
        let key = apiKey ?? ""
        if provider.requiresAPIKey, key.isEmpty { throw ProviderError.missingKey }

        let http = HTTPClient(session: session)
        switch provider {
        case .openAI, .mistral, .openRouter:
            return OpenAICompatibleBackend(provider: provider, http: http, baseURL: baseURL, apiKey: key)
        case .anthropic:
            return AnthropicBackend(http: http, baseURL: baseURL, apiKey: key)
        case .gemini:
            return GeminiBackend(http: http, baseURL: baseURL, apiKey: key)
        case .ollama:
            return OllamaBackend(http: http, baseURL: baseURL)
        case .apple:
            preconditionFailure("Handled above; Apple Intelligence doesn't use HTTP.")
        }
    }

    /// Parses a user-typed server address, falling back to the default when it's blank.
    private static func serverURL(from typed: String?, default fallback: String?) throws -> URL {
        let address = typed?.isEmpty == false ? typed : fallback
        guard let address, let url = URL(string: address), url.scheme?.hasPrefix("http") == true else {
            throw ProviderError.invalidBaseURL
        }
        return url
    }

    /// OpenAI's wording when a completion-only or Responses-only model hits /chat/completions.
    static func isNotAChatModelMessage(_ message: String) -> Bool {
        message.localizedStandardContains("not a chat model")
            || message.localizedStandardContains("not supported in the v1/chat/completions")
            || message.localizedStandardContains("only supported in v1/responses")
    }
}
