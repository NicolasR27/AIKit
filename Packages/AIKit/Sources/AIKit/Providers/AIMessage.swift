import Foundation

/// One turn in a conversation sent with `AIProviderStore.send(_:system:)`.
public nonisolated struct AIMessage: Sendable, Equatable, Codable {
    public enum Role: String, Sendable, Codable {
        case user
        case assistant
    }

    public var role: Role
    public var content: String

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }

    public static func user(_ content: String) -> AIMessage { AIMessage(role: .user, content: content) }
    public static func assistant(_ content: String) -> AIMessage { AIMessage(role: .assistant, content: content) }
}
