import Foundation

extension ProviderClient {
    /// Sends a conversation to the provider's chat endpoint and returns the reply text.
    func chat(
        _ messages: [AIMessage],
        system: String?,
        credentials: AIProviderCredentials,
        model: String
    ) async throws -> String {
        if credentials.provider == .apple {
            return try await AppleIntelligence.chat(messages, system: system)
        }
        guard let baseURL = credentials.baseURL else { throw ProviderError.invalidBaseURL }
        let key = credentials.apiKey ?? ""
        if credentials.provider.requiresAPIKey, key.isEmpty { throw ProviderError.missingKey }

        do {
            return try await chatOverHTTP(messages, system: system, credentials: credentials,
                                          baseURL: baseURL, key: key, model: model)
        } catch ProviderError.server(_, let message?) where Self.isNotAChatModelMessage(message) {
            throw ProviderError.notAChatModel(model)
        }
    }

    /// OpenAI's wording when a completion-only or Responses-only model hits /chat/completions.
    static func isNotAChatModelMessage(_ message: String) -> Bool {
        message.localizedStandardContains("not a chat model")
            || message.localizedStandardContains("not supported in the v1/chat/completions")
            || message.localizedStandardContains("only supported in v1/responses")
    }

    private func chatOverHTTP(
        _ messages: [AIMessage],
        system: String?,
        credentials: AIProviderCredentials,
        baseURL: URL,
        key: String,
        model: String
    ) async throws -> String {
        let reply: String
        switch credentials.provider {
        case .openAI, .mistral, .openRouter:
            // All three speak the OpenAI Chat Completions format.
            var turns = try messages.map { message in
                let images = try message.images.map(ImageEncoding.jpegBase64)
                guard !images.isEmpty else {
                    return OpenAIChat.RequestMessage(role: message.role.rawValue, content: .text(message.content))
                }
                let parts = images.map { OpenAIChat.Part(type: "image_url", image_url: .init(url: "data:image/jpeg;base64,\($0)")) }
                    + [OpenAIChat.Part(type: "text", text: message.content)]
                return OpenAIChat.RequestMessage(role: message.role.rawValue, content: .parts(parts))
            }
            if let system { turns.insert(.init(role: "system", content: .text(system)), at: 0) }
            let data = try await post(
                baseURL.appending(path: "chat/completions"),
                body: OpenAIChat.Request(model: model, messages: turns),
                headers: ["Authorization": "Bearer \(key)"]
            )
            reply = try decode(OpenAIChat.Response.self, data).choices.first?.message.content ?? ""

        case .anthropic:
            let data = try await post(
                baseURL.appending(path: "messages"),
                body: AnthropicChat.Request(
                    model: model,
                    max_tokens: 4096,
                    system: system,
                    messages: try messages.map { message in
                        let images = try message.images.map(ImageEncoding.jpegBase64)
                        guard !images.isEmpty else {
                            return AnthropicChat.Message(role: message.role.rawValue, content: .text(message.content))
                        }
                        let blocks = images.map {
                            AnthropicChat.Block(type: "image", source: .init(type: "base64", media_type: "image/jpeg", data: $0))
                        } + [AnthropicChat.Block(type: "text", text: message.content)]
                        return AnthropicChat.Message(role: message.role.rawValue, content: .blocks(blocks))
                    }
                ),
                headers: ["x-api-key": key, "anthropic-version": "2023-06-01"]
            )
            reply = try decode(AnthropicChat.Response.self, data).content
                .compactMap(\.text)
                .joined()

        case .gemini:
            let data = try await post(
                baseURL.appending(path: "models/\(model):generateContent"),
                body: GeminiChat.Request(
                    systemInstruction: system.map { .init(role: nil, parts: [.init(text: $0)]) },
                    contents: try messages.map { message in
                        let images = try message.images.map {
                            GeminiChat.Part(inlineData: .init(mimeType: "image/jpeg", data: try ImageEncoding.jpegBase64(from: $0)))
                        }
                        return .init(role: message.role == .assistant ? "model" : "user",
                                     parts: images + [.init(text: message.content)])
                    }
                ),
                headers: ["x-goog-api-key": key]
            )
            reply = try decode(GeminiChat.Response.self, data).candidates?.first?.content?.parts?
                .compactMap(\.text)
                .joined() ?? ""

        case .ollama:
            var turns = try messages.map { message in
                let images = try message.images.map(ImageEncoding.jpegBase64)
                return OllamaChat.Message(role: message.role.rawValue, content: message.content,
                                          images: images.isEmpty ? nil : images)
            }
            if let system { turns.insert(.init(role: "system", content: system, images: nil), at: 0) }
            let data = try await post(
                baseURL.appending(path: "api/chat"),
                body: OllamaChat.Request(model: model, messages: turns, stream: false),
                headers: [:]
            )
            reply = try decode(OllamaChat.Response.self, data).message.content

        case .apple:
            preconditionFailure("Handled above; Apple Intelligence doesn't use HTTP.")
        }

        guard !reply.isEmpty else { throw AIKitError.emptyResponse }
        return reply
    }

    private func post(_ url: URL, body: some Encodable, headers: [String: String]) async throws -> Data {
        // Generation can take a while on large models.
        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }
}
