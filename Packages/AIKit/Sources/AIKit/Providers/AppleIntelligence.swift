import Foundation
import FoundationModels

/// Apple's on-device model, reached through the Foundation Models framework instead of HTTP.
enum AppleIntelligence {
    /// Shown as the model name; there's only one on-device model.
    static let modelName = "On-device model"

    /// Throws a user-readable `ProviderError.unavailable` when the model can't be used right now.
    static func checkAvailability() throws {
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

    /// Replays earlier turns as the session transcript, then asks for a reply to the last user message.
    static func chat(_ messages: [AIMessage], system: String?) async throws -> String {
        try checkAvailability()
        guard let last = messages.last, last.role == .user else {
            throw ProviderError.unavailable(String(localized: .mustEndWithUserError))
        }

        var entries: [Transcript.Entry] = []
        if let system {
            entries.append(.instructions(.init(segments: [.text(.init(content: system))], toolDefinitions: [])))
        }
        if messages.contains(where: { !$0.images.isEmpty }),
           !SystemLanguageModel.default.capabilities.contains(.vision) {
            throw ProviderError.imagesNotSupported(
                String(localized: .photosNotSupportedError)
            )
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

        let session = LanguageModelSession(transcript: Transcript(entries: entries))
        let attachments = try last.images.map { Attachment(try ImageEncoding.cgImage(from: $0)) }
        let reply = try await session.respond {
            for attachment in attachments { attachment }
            last.content
        }.content
        guard !reply.isEmpty else { throw AIKitError.emptyResponse }
        return reply
    }
}
