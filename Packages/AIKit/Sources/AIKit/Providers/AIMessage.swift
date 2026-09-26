import Foundation

/// One turn in a conversation sent with `AIProviderStore.send(_:system:)`.
public nonisolated struct AIMessage: Sendable, Equatable, Codable {
    public enum Role: String, Sendable, Codable {
        case user
        case assistant
    }

    public var role: Role
    public var content: String
    /// Photos sent with the text, as image file bytes (JPEG, PNG, HEIC…), e.g. from a `PhotosPicker`.
    public var images: [Data]

    public init(role: Role, content: String, images: [Data] = []) {
        self.role = role
        self.content = content
        self.images = images
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(Role.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([Data].self, forKey: .images) ?? []
    }

    public static func user(_ content: String, images: [Data] = []) -> AIMessage {
        AIMessage(role: .user, content: content, images: images)
    }
    public static func assistant(_ content: String) -> AIMessage { AIMessage(role: .assistant, content: content) }
}
