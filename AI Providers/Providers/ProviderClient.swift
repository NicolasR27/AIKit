import Foundation
import FoundationModels

enum ProviderError: LocalizedError {
    case missingKey
    case invalidBaseURL
    case invalidKey(String?)
    case server(status: Int, message: String?)
    case unreachable(String)
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            "Enter an API key first."
        case .invalidBaseURL:
            "That server address isn't a valid URL."
        case .invalidKey(let message):
            message ?? "The provider rejected this API key."
        case .server(let status, let message):
            message ?? "The provider returned HTTP \(status)."
        case .unreachable(let detail):
            "Couldn't reach the provider. \(detail)"
        case .unavailable(let reason):
            reason
        }
    }
}

/// Verifies credentials by listing the models the key can access.
/// A successful model list doubles as proof the key works.
struct ProviderClient {
    var session: URLSession = .shared

    func fetchModels(for provider: AIProvider, apiKey: String?, baseURL: String?) async throws -> [String] {
        switch provider {
        case .apple:
            return try appleModels()

        case .openAI:
            let data = try await get("https://api.openai.com/v1/models", bearer: apiKey)
            return try decode(DataList.self, data).data.map(\.id).sorted()

        case .anthropic:
            guard let apiKey, !apiKey.isEmpty else { throw ProviderError.missingKey }
            let data = try await get("https://api.anthropic.com/v1/models?limit=1000", headers: [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
            ])
            // Anthropic already returns newest first.
            return try decode(DataList.self, data).data.map(\.id)

        case .gemini:
            guard let apiKey, !apiKey.isEmpty else { throw ProviderError.missingKey }
            let data = try await get("https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000",
                                     headers: ["x-goog-api-key": apiKey])
            return try decode(GeminiModels.self, data).models
                .filter { $0.supportedGenerationMethods?.contains("generateContent") ?? true }
                .map { $0.name.replacingOccurrences(of: "models/", with: "") }
                .sorted()

        case .mistral:
            let data = try await get("https://api.mistral.ai/v1/models", bearer: apiKey)
            return Array(Set(try decode(DataList.self, data).data.map(\.id))).sorted()

        case .openRouter:
            // The models endpoint is public, so hit /key to actually validate the key.
            _ = try await get("https://openrouter.ai/api/v1/key", bearer: apiKey)
            let data = try await get("https://openrouter.ai/api/v1/models", bearer: apiKey)
            return try decode(DataList.self, data).data.map(\.id).sorted()

        case .ollama:
            let base = (baseURL?.isEmpty == false ? baseURL : provider.defaultBaseURL) ?? ""
            let trimmed = base.hasSuffix("/") ? String(base.dropLast()) : base
            let data = try await get(trimmed + "/api/tags")
            return try decode(OllamaTags.self, data).models.map(\.name).sorted()
        }
    }

    // MARK: - Apple Intelligence

    private func appleModels() throws -> [String] {
        switch SystemLanguageModel.default.availability {
        case .available:
            return ["On-device model"]
        case .unavailable(.deviceNotEligible):
            throw ProviderError.unavailable("This device doesn't support Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            throw ProviderError.unavailable("Turn on Apple Intelligence in Settings to use the on-device model.")
        case .unavailable(.modelNotReady):
            throw ProviderError.unavailable("The on-device model is still downloading. Try again shortly.")
        case .unavailable:
            throw ProviderError.unavailable("Apple Intelligence isn't available right now.")
        }
    }

    // MARK: - Networking

    private func get(_ urlString: String, bearer: String?) async throws -> Data {
        guard let bearer, !bearer.isEmpty else { throw ProviderError.missingKey }
        return try await get(urlString, headers: ["Authorization": "Bearer \(bearer)"])
    }

    private func get(_ urlString: String, headers: [String: String] = [:]) async throws -> Data {
        guard let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true else {
            throw ProviderError.invalidBaseURL
        }
        var request = URLRequest(url: url, timeoutInterval: 15)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw ProviderError.unreachable(error.localizedDescription)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let message = try? JSONDecoder().decode(ErrorEnvelope.self, from: data).error.message
            if status == 401 || status == 403 {
                throw ProviderError.invalidKey(message)
            }
            throw ProviderError.server(status: status, message: message)
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ProviderError.server(status: 200, message: "Unexpected response from the provider.")
        }
    }
}

// MARK: - Response shapes

private struct DataList: Decodable {
    struct Item: Decodable { let id: String }
    let data: [Item]
}

private struct GeminiModels: Decodable {
    struct Model: Decodable {
        let name: String
        let supportedGenerationMethods: [String]?
    }
    let models: [Model]
}

private struct OllamaTags: Decodable {
    struct Model: Decodable { let name: String }
    let models: [Model]
}

/// OpenAI, Anthropic, Gemini, Mistral and OpenRouter all nest errors as `{"error": {"message": ...}}`.
private struct ErrorEnvelope: Decodable {
    struct Body: Decodable { let message: String? }
    let error: Body
}
