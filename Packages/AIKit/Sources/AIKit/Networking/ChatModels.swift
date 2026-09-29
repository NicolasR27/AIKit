import Foundation

/// OpenAI's and Mistral's model lists include models that can't chat (embeddings, speech,
/// images, moderation, legacy completions, Responses-only). Picking one makes every
/// `/chat/completions` call fail, so they're kept out of the picker.
nonisolated enum ChatModels {
    private static let openAIExcluded = [
        "embedding", "whisper", "tts", "dall-e", "image", "moderation", "transcribe",
        "audio", "realtime", "instruct", "davinci", "babbage", "codex", "computer-use",
        "deep-research", "sora",
    ]
    private static let mistralExcluded = ["embed", "moderation", "ocr", "transcribe"]

    static func isChatModel(_ id: String, for provider: AIProvider) -> Bool {
        let id = id.lowercased()
        switch provider {
        case .openAI:
            // o1-pro, o3-pro, gpt-5-pro and friends only work with the Responses API.
            if id.contains("-pro") { return false }
            return !openAIExcluded.contains { id.contains($0) }
        case .mistral:
            return !mistralExcluded.contains { id.contains($0) }
        default:
            return true
        }
    }

    static func filter(_ ids: [String], for provider: AIProvider) -> [String] {
        ids.filter { isChatModel($0, for: provider) }
    }
}
