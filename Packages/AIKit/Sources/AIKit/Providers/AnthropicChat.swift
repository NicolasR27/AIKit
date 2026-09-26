import Foundation

/// Anthropic Messages API JSON.
enum AnthropicChat {
    enum Content: Encodable {
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
    struct Block: Encodable {
        struct Source: Encodable { let type: String; let media_type: String; let data: String }
        let type: String
        var text: String?
        var source: Source?
    }
    struct Message: Encodable { let role: String; let content: Content }
    struct Request: Encodable {
        let model: String
        let max_tokens: Int
        let system: String?
        let messages: [Message]
    }
    struct Response: Decodable {
        struct TextBlock: Decodable { let text: String? }
        let content: [TextBlock]
    }
}
