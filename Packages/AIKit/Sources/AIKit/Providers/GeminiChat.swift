import Foundation

/// Gemini generateContent JSON.
enum GeminiChat {
    struct InlineData: Codable { let mimeType: String; let data: String }
    struct Part: Codable {
        var text: String?
        var inlineData: InlineData?
    }
    struct Content: Codable { let role: String?; let parts: [Part]? }
    struct Request: Encodable {
        let systemInstruction: Content?
        let contents: [Content]
    }
    struct Response: Decodable {
        struct Candidate: Decodable { let content: Content? }
        let candidates: [Candidate]?
    }
}
