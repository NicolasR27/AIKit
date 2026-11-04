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

    /// Uses Anthropic's server-side web search and web fetch tools: Claude searches, opens the
    /// pages it wants, and cites them, all inside one request.
    func searchWeb(_ messages: [AIMessage], system: String?, model: String) async throws -> AIAnswer {
        let turns = try messages.map(Message.init)
        var blocks: [JSONValue] = []

        // Anthropic pauses a long search (`pause_turn`); sending the turn back resumes it.
        for _ in 0..<Self.maxContinuations {
            let paused = blocks.isEmpty ? [] : [Message(role: "assistant", content: .raw(blocks))]
            let data = try await http.post(
                baseURL.appending(path: "messages"),
                body: SearchRequest(
                    model: model,
                    max_tokens: 8192,
                    system: system,
                    messages: turns + paused,
                    tools: Tool.webTools(for: model)
                ),
                headers: headers,
                timeout: HTTPClient.webSearchTimeout
            )
            let response = try http.decode(SearchResponse.self, from: data)
            blocks += response.content
            if response.stop_reason != "pause_turn" { break }
        }
        return Self.answer(from: blocks)
    }

    private static let maxContinuations = 4

    /// The reply is the text after the last search or page read (before it, Claude just says
    /// what it's about to look up). Sources are the pages it cited plus the pages it opened.
    static func answer(from blocks: [JSONValue]) -> AIAnswer {
        let lastTool = blocks.lastIndex { $0["type"]?.string?.hasSuffix("tool_result") == true }
        let answerBlocks = lastTool.map { blocks[($0 + 1)...] } ?? blocks[...]
        let texts = answerBlocks.filter { $0["type"]?.string == "text" }

        var pages: [(title: String?, url: String?)] = texts.flatMap { text in
            text["citations"]?.elements.map { ($0["title"]?.string, $0["url"]?.string) } ?? []
        }
        for block in blocks where block["type"]?.string == "web_fetch_tool_result" {
            let result = block["content"]
            pages.append((result?["content"]?["title"]?.string, result?["url"]?.string))
        }
        return AIAnswer(text: texts.compactMap { $0["text"]?.string }.joined(), sources: AIWebSource.list(pages))
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

private struct SearchRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String?
    let messages: [Message]
    let tools: [Tool]
}

private struct Tool: Encodable {
    let type: String
    let name: String
    let max_uses: Int

    /// Newer models get the versions that filter results before reading them; older models
    /// (Claude 3, Haiku, 4.5 and earlier) only have basic search.
    static func webTools(for model: String) -> [Tool] {
        let id = model.lowercased()
        let isOlderModel = id.contains("claude-3") || id.contains("haiku")
            || ["-4-0", "-4-1", "-4-5", "-4-2025"].contains { id.contains($0) }
        if isOlderModel {
            return [Tool(type: "web_search_20250305", name: "web_search", max_uses: 5)]
        }
        return [
            Tool(type: "web_search_20260209", name: "web_search", max_uses: 5),
            Tool(type: "web_fetch_20260209", name: "web_fetch", max_uses: 5),
        ]
    }
}

private struct Message: Encodable {
    let role: String
    let content: Content

    init(role: String, content: Content) {
        self.role = role
        self.content = content
    }

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
    /// Blocks from a paused reply, sent back exactly as they arrived.
    case raw([JSONValue])

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text): try container.encode(text)
        case .blocks(let blocks): try container.encode(blocks)
        case .raw(let blocks): try container.encode(blocks)
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

private struct SearchResponse: Decodable {
    let stop_reason: String?
    let content: [JSONValue]
}
