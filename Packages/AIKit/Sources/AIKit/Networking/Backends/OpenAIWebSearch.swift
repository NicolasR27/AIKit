import Foundation

/// OpenAI only offers web search for its regular models through the Responses API
/// (`/responses` with the `web_search` tool), not Chat Completions.
extension OpenAICompatibleBackend {
    func openAIWebSearch(_ messages: [AIMessage], system: String?, model: String) async throws -> AIAnswer {
        let data = try await http.post(
            baseURL.appending(path: "responses"),
            body: ResponsesRequest(
                model: model,
                instructions: system,
                input: try messages.map(InputMessage.init),
                tools: [ResponsesTool(type: "web_search", external_web_access: true)],
                tool_choice: "required",
                store: false
            ),
            headers: HTTPClient.bearer(apiKey),
            timeout: HTTPClient.webSearchTimeout
        )
        // The final message item is the answer; earlier ones are progress notes.
        let parts = try http.decode(ResponsesResponse.self, from: data).output
            .last { $0.type == "message" }?
            .content?.filter { $0.type == "output_text" } ?? []
        let pages = parts.flatMap { $0.annotations ?? [] }
            .filter { $0.type == "url_citation" }
            .map { ($0.title, $0.url) }
        return AIAnswer(text: parts.compactMap(\.text).joined(), sources: AIWebSource.list(pages))
    }
}

// MARK: - Wire format

private struct ResponsesRequest: Encodable {
    let model: String
    let instructions: String?
    let input: [InputMessage]
    let tools: [ResponsesTool]
    /// `required`: the model must search; with the default `auto` it may answer from memory.
    let tool_choice: String
    /// Don't keep the conversation on OpenAI's servers; AIKit resends history every time.
    let store: Bool
}

private struct ResponsesTool: Encodable {
    let type: String
    /// Fetch live pages, not OpenAI's cached index. True is the documented default; spelled out so it stays that way.
    let external_web_access: Bool
}

private struct InputMessage: Encodable {
    let role: String
    let content: InputContent

    /// A plain string for text-only turns, or image parts followed by the text when the turn has photos.
    init(_ message: AIMessage) throws {
        let images = try message.images.map(ImageEncoding.jpegBase64)
        role = message.role.rawValue
        content = images.isEmpty
            ? .text(message.content)
            : .parts(images.map { .image(dataURL: "data:image/jpeg;base64,\($0)") } + [.text(message.content)])
    }
}

private enum InputContent: Encodable {
    case text(String)
    case parts([InputPart])

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text): try container.encode(text)
        case .parts(let parts): try container.encode(parts)
        }
    }
}

private struct InputPart: Encodable {
    let type: String
    var text: String?
    var image_url: String?

    static func text(_ text: String) -> InputPart { InputPart(type: "input_text", text: text) }
    static func image(dataURL: String) -> InputPart { InputPart(type: "input_image", image_url: dataURL) }
}

private struct ResponsesResponse: Decodable {
    struct Item: Decodable {
        let type: String
        var content: [Part]?
    }
    struct Part: Decodable {
        let type: String
        var text: String?
        var annotations: [Annotation]?
    }
    struct Annotation: Decodable {
        let type: String
        var url: String?
        var title: String?
    }
    let output: [Item]
}
