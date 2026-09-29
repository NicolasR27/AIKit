import Foundation

/// Gemini generateContent API.
struct GeminiBackend: ProviderBackend {
    let http: HTTPClient
    let baseURL: URL
    let apiKey: String

    private var headers: [String: String] { ["x-goog-api-key": apiKey] }

    func models() async throws -> [String] {
        let url = baseURL.appending(path: "models").appending(queryItems: [URLQueryItem(name: "pageSize", value: "1000")])
        let data = try await http.get(url, headers: headers)
        return try http.decode(ModelList.self, from: data).models
            .filter { $0.supportedGenerationMethods?.contains("generateContent") ?? true }
            .map { String($0.name.trimmingPrefix("models/")) }
            .sorted()
    }

    func reply(to messages: [AIMessage], system: String?, model: String) async throws -> String {
        let data = try await http.post(
            baseURL.appending(path: "models/\(model):generateContent"),
            body: Request(
                systemInstruction: system.map { Content(role: nil, parts: [Part(text: $0)]) },
                contents: try messages.map(Content.init)
            ),
            headers: headers
        )
        return try http.decode(Response.self, from: data).candidates?.first?.content?.parts?
            .compactMap(\.text)
            .joined() ?? ""
    }
}

// MARK: - Wire format

private struct ModelList: Decodable {
    struct Model: Decodable {
        let name: String
        let supportedGenerationMethods: [String]?
    }
    let models: [Model]
}

private struct Request: Encodable {
    let systemInstruction: Content?
    let contents: [Content]
}

private struct Content: Codable {
    let role: String?
    let parts: [Part]?

    init(role: String?, parts: [Part]) {
        self.role = role
        self.parts = parts
    }

    /// Gemini calls the assistant "model", and takes image parts ahead of the text.
    init(_ message: AIMessage) throws {
        role = message.role == .assistant ? "model" : "user"
        parts = try message.images.map {
            Part(inlineData: InlineData(mimeType: "image/jpeg", data: try ImageEncoding.jpegBase64(from: $0)))
        } + [Part(text: message.content)]
    }
}

private struct Part: Codable {
    var text: String?
    var inlineData: InlineData?
}

private struct InlineData: Codable {
    let mimeType: String
    let data: String
}

private struct Response: Decodable {
    struct Candidate: Decodable { let content: Content? }
    let candidates: [Candidate]?
}
