import Foundation

/// Mistral's web search isn't in Chat Completions; it's a built-in tool of the Conversations API.
extension OpenAICompatibleBackend {
    func mistralWebSearch(_ messages: [AIMessage], system: String?, model: String) async throws -> AIAnswer {
        let data = try await http.post(
            baseURL.appending(path: "conversations"),
            body: ConversationRequest(
                model: model,
                inputs: try messages.map(InputEntry.init),
                instructions: system,
                tools: [ConversationTool(type: "web_search")],
                store: false
            ),
            headers: HTTPClient.bearer(apiKey),
            timeout: HTTPClient.webSearchTimeout
        )
        guard let content = try http.decode(ConversationResponse.self, from: data).outputs
            .last(where: { $0.type == "message.output" })?.content else { return AIAnswer(text: "") }

        switch content {
        case .text(let text):
            return AIAnswer(text: text)
        case .chunks(let chunks):
            // Text chunks are the reply; tool_reference chunks between them are its citations.
            let pages = chunks.filter { $0.type == "tool_reference" }.map { ($0.title, $0.url) }
            let text = chunks.filter { $0.type == "text" }.compactMap(\.text).joined()
            return AIAnswer(text: text, sources: AIWebSource.list(pages))
        }
    }
}

// MARK: - Wire format

private struct ConversationRequest: Encodable {
    let model: String
    let inputs: [InputEntry]
    let instructions: String?
    let tools: [ConversationTool]
    /// Don't keep the conversation on Mistral's servers; AIKit resends history every time.
    let store: Bool
}

private struct ConversationTool: Encodable {
    let type: String
}

private struct InputEntry: Encodable {
    let role: String
    let content: InputContent

    /// A plain string for text-only turns, or image chunks followed by the text when the turn has photos.
    init(_ message: AIMessage) throws {
        let images = try message.images.map(ImageEncoding.jpegBase64)
        role = message.role.rawValue
        content = images.isEmpty
            ? .text(message.content)
            : .chunks(images.map { .image(dataURL: "data:image/jpeg;base64,\($0)") } + [.text(message.content)])
    }
}

private enum InputContent: Encodable {
    case text(String)
    case chunks([InputChunk])

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text): try container.encode(text)
        case .chunks(let chunks): try container.encode(chunks)
        }
    }
}

private struct InputChunk: Encodable {
    let type: String
    var text: String?
    var image_url: String?

    static func text(_ text: String) -> InputChunk { InputChunk(type: "text", text: text) }
    static func image(dataURL: String) -> InputChunk { InputChunk(type: "image_url", image_url: dataURL) }
}

private struct ConversationResponse: Decodable {
    struct Entry: Decodable {
        let type: String
        var content: OutputContent?
    }
    let outputs: [Entry]
}

/// A reply's content is a plain string, or a list of chunks when it carries citations.
private enum OutputContent: Decodable {
    case text(String)
    case chunks([OutputChunk])

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else {
            self = .chunks(try container.decode([OutputChunk].self))
        }
    }
}

private struct OutputChunk: Decodable {
    let type: String
    var text: String?
    var title: String?
    var url: String?
}
