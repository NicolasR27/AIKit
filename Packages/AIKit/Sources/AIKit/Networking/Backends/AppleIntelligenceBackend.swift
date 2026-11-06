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

    /// Room kept free for the reply. The context holds the prompt, any search results and the reply.
    static let replyReserve = 2_000

    /// Replays earlier turns as the session transcript, then asks for a reply to the last user message.
    func reply(to messages: [AIMessage], system: String?, model: String) async throws -> String {
        try await respond(to: messages, system: system, search: nil)
    }

    /// Gives the model a `searchWeb` tool and lets it search as often as it needs before answering.
    func searchWeb(_ messages: [AIMessage], system: String?, model: String) async throws -> AIAnswer {
        guard let searchEngine else { throw AIKitError.webSearchNotSupported(.apple) }
        let tool = AppleWebSearchTool(engine: searchEngine)
        do {
            let text = try await respond(to: messages, system: AppleWebSearchTool.steered(system), search: tool)
            return AIAnswer(text: text, sources: tool.log.sources)
        } catch let error as LanguageModelSession.ToolCallError {
            // Surface the search provider's own error ("invalid key", "rate limited"…).
            throw error.underlyingError
        }
    }

    /// If the context still overflows (a longer reply than expected), tries once more with twice the
    /// room for the reply, then gives up with a readable message instead of the raw token counts.
    private func respond(to messages: [AIMessage], system: String?, search: AppleWebSearchTool?) async throws -> String {
        do {
            return try await respond(to: messages, system: system, search: search, replyReserve: Self.replyReserve)
        } catch where Self.isContextFull(error) {
            do {
                return try await respond(to: messages, system: system, search: search, replyReserve: Self.replyReserve * 2)
            } catch where Self.isContextFull(error) {
                throw ProviderError.unavailable(String(localized: .appleContextFullError))
            }
        }
    }

    private func respond(
        to messages: [AIMessage],
        system: String?,
        search: AppleWebSearchTool?,
        replyReserve: Int
    ) async throws -> String {
        try Self.checkAvailability()
        guard let last = messages.last, last.role == .user else {
            throw ProviderError.unavailable(String(localized: .mustEndWithUserError))
        }
        if messages.contains(where: { !$0.images.isEmpty }),
           !SystemLanguageModel.default.capabilities.contains(.vision) {
            throw ProviderError.imagesNotSupported(String(localized: .photosNotSupportedError))
        }

        let tools: [any Tool] = search.map { [$0] } ?? []
        var instructions: [Transcript.Entry] = []
        if let system {
            let definitions = tools.map { Transcript.ToolDefinition(tool: $0) }
            instructions.append(.instructions(.init(segments: [.text(.init(content: system))], toolDefinitions: definitions)))
        }
        var history: [Transcript.Entry] = try messages.dropLast().map { message in
            let segments = try Self.segments(for: message)
            switch message.role {
            case .user: return .prompt(.init(segments: segments))
            case .assistant: return .response(.init(assetIDs: [], segments: segments))
            }
        }
        let prompt = Transcript.Entry.prompt(.init(segments: try Self.segments(for: last)))

        // Drop the oldest turns until the conversation leaves room for the reply.
        let model = SystemLanguageModel.default
        let available = model.contextSize - replyReserve
        var used = try await model.tokenCount(for: instructions + history + [prompt])
        while used > available, !history.isEmpty {
            history.removeFirst()
            while case .response = history.first { history.removeFirst() }
            used = try await model.tokenCount(for: instructions + history + [prompt])
        }
        guard used <= available else {
            throw ProviderError.unavailable(String(localized: .appleContextFullError))
        }
        search?.budget.set(available - used)

        let session = LanguageModelSession(tools: tools, transcript: Transcript(entries: instructions + history))
        let attachments = try last.images.map { Attachment(try ImageEncoding.cgImage(from: $0)) }
        return try await session.respond {
            for attachment in attachments { attachment }
            last.content
        }.content
    }

    private static func segments(for message: AIMessage) throws -> [Transcript.Segment] {
        let images: [Transcript.Segment] = try message.images.map {
            .attachment(.init(content: .image(.init(try ImageEncoding.cgImage(from: $0)))))
        }
        return images + [.text(.init(content: message.content))]
    }

    static func isContextFull(_ error: any Error) -> Bool {
        switch error {
        case LanguageModelError.contextSizeExceeded: true
        case LanguageModelSession.GenerationError.exceededContextWindowSize: true
        default: false
        }
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
