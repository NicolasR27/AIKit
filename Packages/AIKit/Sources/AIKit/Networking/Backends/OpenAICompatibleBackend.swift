import Foundation

/// OpenAI Chat Completions, which Mistral and OpenRouter speak too.
struct OpenAICompatibleBackend: ProviderBackend {
    let provider: AIProvider
    let http: HTTPClient
    let baseURL: URL
    let apiKey: String

    func models() async throws -> [String] {
        let auth = HTTPClient.bearer(apiKey)
        if provider == .openRouter {
            // OpenRouter's model list is public, so hit /key to actually validate the key.
            _ = try await http.get(baseURL.appending(path: "key"), headers: auth)
        }
        let data = try await http.get(baseURL.appending(path: "models"), headers: auth)
        // Mistral lists some models twice.
        let ids = Set(try http.decode(ModelList.self, from: data).data.map(\.id))
        return ChatModels.filter(Array(ids), for: provider).sorted()
    }

    func reply(to messages: [AIMessage], system: String?, model: String) async throws -> String {
        var turns = try messages.map(RequestMessage.init)
        if let system { turns.insert(RequestMessage(role: "system", content: .text(system)), at: 0) }

        let data = try await http.post(
            baseURL.appending(path: "chat/completions"),
            body: Request(model: model, messages: turns),
            headers: HTTPClient.bearer(apiKey)
        )
        return try http.decode(Response.self, from: data).choices.first?.message.content ?? ""
    }

    /// Each provider has its own way to search: OpenAI's Responses API, Mistral's Conversations
    /// API, and OpenRouter's web plugin, which works with every model it offers.
    func searchWeb(_ messages: [AIMessage], system: String?, model: String) async throws -> AIAnswer {
        switch provider {
        case .openAI:
            return try await openAIWebSearch(messages, system: system, model: model)
        case .mistral:
            return try await mistralWebSearch(messages, system: system, model: model)
        default:
            var turns = try messages.map(RequestMessage.init)
            if let system { turns.insert(RequestMessage(role: "system", content: .text(system)), at: 0) }

            let data = try await http.post(
                baseURL.appending(path: "chat/completions"),
                body: Request(model: model, messages: turns, plugins: [Plugin(id: "web")]),
                headers: HTTPClient.bearer(apiKey),
                timeout: HTTPClient.webSearchTimeout
            )
            let message = try http.decode(Response.self, from: data).choices.first?.message
            let pages = message?.annotations?.compactMap(\.url_citation).map { ($0.title, $0.url) } ?? []
            return AIAnswer(text: message?.content ?? "", sources: AIWebSource.list(pages))
        }
    }
}

// MARK: - Wire format

private struct ModelList: Decodable {
    struct Item: Decodable { let id: String }
    let data: [Item]
}

private struct Request: Encodable {
    let model: String
    let messages: [RequestMessage]
    var plugins: [Plugin]?
}

/// OpenRouter's add-ons; `web` searches with the model's own provider when it can, Exa otherwise.
private struct Plugin: Encodable {
    let id: String
}

private struct RequestMessage: Encodable {
    let role: String
    let content: Content

    init(role: String, content: Content) {
        self.role = role
        self.content = content
    }

    /// A plain string for text-only turns, or image parts followed by the text when the turn has photos.
    init(_ message: AIMessage) throws {
        let images = try message.images.map(ImageEncoding.jpegBase64)
        role = message.role.rawValue
        content = images.isEmpty
            ? .text(message.content)
            : .parts(images.map { .image(dataURL: "data:image/jpeg;base64,\($0)") } + [.text(message.content)])
    }
}

private enum Content: Encodable {
    case text(String)
    case parts([Part])

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text): try container.encode(text)
        case .parts(let parts): try container.encode(parts)
        }
    }
}

private struct Part: Encodable {
    struct ImageURL: Encodable { let url: String }
    let type: String
    var text: String?
    var image_url: ImageURL?

    static func text(_ text: String) -> Part { Part(type: "text", text: text) }
    static func image(dataURL: String) -> Part { Part(type: "image_url", image_url: ImageURL(url: dataURL)) }
}

private struct Response: Decodable {
    struct Choice: Decodable { let message: Message }
    struct Message: Decodable {
        let content: String?
        var annotations: [Annotation]?
    }
    struct Annotation: Decodable { let url_citation: Citation? }
    struct Citation: Decodable { let url: String?; let title: String? }
    let choices: [Choice]
}
