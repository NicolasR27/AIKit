import Foundation
import FoundationModels

/// Apple's on-device model, reached through the Foundation Models framework instead of HTTP.
struct AppleIntelligenceBackend: ProviderBackend {
    /// Shown as the model name; there's only one on-device model.
    static let modelName = "On-device model"

    func models() async throws -> [String] {
        try Self.checkAvailability()
        return [Self.modelName]
    }

    /// Where the model's search tool looks things up. `nil` means it can't search.
    var searchEngine: (any AIWebSearchEngine)?

    /// Replays earlier turns as the session transcript, then asks for a reply to the last user message.
    func reply(to messages: [AIMessage], system: String?, model: String) async throws -> String {
        try await respond(to: messages, system: system, tools: [])
    }

    /// Gives the model a `searchWeb` tool and lets it search as often as it needs before answering.
    func searchWeb(_ messages: [AIMessage], system: String?, model: String) async throws -> AIAnswer {
        guard let searchEngine else { throw AIKitError.webSearchNotSupported(.apple) }
        let tool = AppleWebSearchTool(engine: searchEngine)
        do {
            let text = try await respond(to: messages, system: AppleWebSearchTool.steered(system), tools: [tool])
            return AIAnswer(text: text, sources: tool.log.sources)
        } catch let error as LanguageModelSession.ToolCallError {
            // Surface the search provider's own error ("invalid key", "rate limited"…).
            throw error.underlyingError
        }
    }

    private func respond(to messages: [AIMessage], system: String?, tools: [any Tool]) async throws -> String {
        try Self.checkAvailability()
        guard let last = messages.last, last.role == .user else {
            throw ProviderError.unavailable(String(localized: .mustEndWithUserError))
        }
        if messages.contains(where: { !$0.images.isEmpty }),
           !SystemLanguageModel.default.capabilities.contains(.vision) {
            throw ProviderError.imagesNotSupported(String(localized: .photosNotSupportedError))
        }

        var entries: [Transcript.Entry] = []
        if let system {
            let definitions = tools.map { Transcript.ToolDefinition(tool: $0) }
            entries.append(.instructions(.init(segments: [.text(.init(content: system))], toolDefinitions: definitions)))
        }
        for message in messages.dropLast() {
            let images: [Transcript.Segment] = try message.images.map {
                .attachment(.init(content: .image(.init(try ImageEncoding.cgImage(from: $0)))))
            }
            let segments: [Transcript.Segment] = images + [.text(.init(content: message.content))]
            switch message.role {
            case .user: entries.append(.prompt(.init(segments: segments)))
            case .assistant: entries.append(.response(.init(assetIDs: [], segments: segments)))
            }
        }

        let session = LanguageModelSession(tools: tools, transcript: Transcript(entries: entries))
        let attachments = try last.images.map { Attachment(try ImageEncoding.cgImage(from: $0)) }
        return try await session.respond {
            for attachment in attachments { attachment }
            last.content
        }.content
    }

    /// Throws a user-readable `ProviderError.unavailable` when the model can't be used right now.
    private static func checkAvailability() throws {
        switch SystemLanguageModel.default.availability {
        case .available:
            return
        case .unavailable(.deviceNotEligible):
            throw ProviderError.unavailable(String(localized: .deviceNotEligibleError))
        case .unavailable(.appleIntelligenceNotEnabled):
            throw ProviderError.unavailable(String(localized: .appleIntelligenceOffError))
        case .unavailable(.modelNotReady):
            throw ProviderError.unavailable(String(localized: .modelNotReadyError))
        case .unavailable:
            throw ProviderError.unavailable(String(localized: .appleIntelligenceUnavailableError))
        }
    }
}
