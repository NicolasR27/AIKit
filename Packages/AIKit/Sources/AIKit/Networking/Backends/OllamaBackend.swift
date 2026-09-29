import Foundation

/// Ollama's local server: /api/tags and /api/chat. No key.
struct OllamaBackend: ProviderBackend {
    let http: HTTPClient
    let baseURL: URL

    func models() async throws -> [String] {
        let data = try await http.get(baseURL.appending(path: "api/tags"))
        return try http.decode(Tags.self, from: data).models.map(\.name).sorted()
    }

    func reply(to messages: [AIMessage], system: String?, model: String) async throws -> String {
        var turns = try messages.map(Message.init)
        if let system { turns.insert(Message(role: "system", content: system), at: 0) }

        let data = try await http.post(
            baseURL.appending(path: "api/chat"),
            body: Request(model: model, messages: turns, stream: false)
        )
        return try http.decode(Response.self, from: data).message.content
    }
}

// MARK: - Wire format

private struct Tags: Decodable {
    struct Model: Decodable { let name: String }
    let models: [Model]
}

private struct Request: Encodable {
    let model: String
    let messages: [Message]
    let stream: Bool
}

private struct Message: Codable {
    let role: String
    let content: String
    var images: [String]?

    init(role: String, content: String, images: [String]? = nil) {
        self.role = role
        self.content = content
        self.images = images
    }

    init(_ message: AIMessage) throws {
        let images = try message.images.map(ImageEncoding.jpegBase64)
        self.init(role: message.role.rawValue, content: message.content, images: images.isEmpty ? nil : images)
    }
}

private struct Response: Decodable {
    let message: Message
}
