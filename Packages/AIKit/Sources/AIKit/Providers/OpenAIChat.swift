import Foundation

/// Chat Completions JSON, shared by OpenAI, Mistral and OpenRouter.
enum OpenAIChat {
    struct Message: Decodable { let role: String; let content: String? }
    /// A plain string for text-only turns, or text + image parts when the turn has photos.
    enum Content: Encodable {
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
    struct Part: Encodable {
        struct ImageURL: Encodable { let url: String }
        let type: String
        var text: String?
        var image_url: ImageURL?
    }
    struct RequestMessage: Encodable { let role: String; let content: Content }
    struct Request: Encodable { let model: String; let messages: [RequestMessage] }
    struct Response: Decodable {
        struct Choice: Decodable { let message: Message }
        let choices: [Choice]
    }
}
