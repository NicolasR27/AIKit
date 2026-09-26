import Foundation

/// Ollama /api/chat JSON.
enum OllamaChat {
    struct Message: Codable { let role: String; let content: String; var images: [String]? }
    struct Request: Encodable { let model: String; let messages: [Message]; let stream: Bool }
    struct Response: Decodable { let message: Message }
}
