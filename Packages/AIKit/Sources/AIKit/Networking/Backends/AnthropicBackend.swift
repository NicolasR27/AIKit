import Foundation

/// Anthropic Messages API.
struct AnthropicBackend: ProviderBackend {
    let http: HTTPClient
    let baseURL: URL
    let apiKey: String

    private var headers: [String: String] {
        ["x-api-key": apiKey, "anthropic-version": "2023-06-01"]
    }

    func models() async throws -> [String] {
        let url = baseURL.appending(path: "models").appending(queryItems: [URLQueryItem(name: "limit", value: "1000")])
        let data = try await http.get(url, headers: headers)
        // Anthropic already returns newest first.
        return try http.decode(ModelList.self, from: data).data.map(\.id)
    }

    func reply(to messages: [AIMessage], system: String?, model: String) async throws -> String {
        let data = try await http.post(
            baseURL.appending(path: "messages"),
            body: Request(model: model, max_tokens: 4096, system: system, messages: try messages.map(Message.init)),
            headers: headers
        )
        return try http.decode(Response.self, from: data).content.compactMap(\.text).joined()
    }
}

// MARK: - Wire format

private struct ModelList: Decodable {
    struct Item: Decodable { let id: String }
    let data: [Item]
}

private struct Request: Encodable {
    let model: String
    let max_tokens: Int
    let system: String?
    let messages: [Message]
}

private struct Message: Encodable {
    let role: String
    let content: Content

    /// A plain string for text-only turns, or image blocks followed by the text when the turn has photos.
    init(_ message: AIMessage) throws {
        let images = try message.images.map(ImageEncoding.jpegBase64)
        role = message.role.rawValue
        content = images.isEmpty
            ? .text(message.content)
            : .blocks(images.map(Block.jpeg) + [.text(message.content)])
    }
}

private enum Content: Encodable {
    case text(String)
    case blocks([Block])

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text): try container.encode(text)
        case .blocks(let blocks): try container.encode(blocks)
        }
    }
}

private struct Block: Encodable {
    struct Source: Encodable { let type: String; let media_type: String; let data: String }
    let type: String
    var text: String?
    var source: Source?

    static func text(_ text: String) -> Block { Block(type: "text", text: text) }
    static func jpeg(base64: String) -> Block {
        Block(type: "image", source: Source(type: "base64", media_type: "image/jpeg", data: base64))
    }
}

private struct Response: Decodable {
    struct TextBlock: Decodable { let text: String? }
    let content: [TextBlock]
}
