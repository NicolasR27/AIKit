import Foundation

/// Verifies credentials by listing the models the key can access.
/// A successful model list doubles as proof the key works.
struct ProviderClient {
    var session: URLSession = .shared

    func fetchModels(for provider: AIProvider, apiKey: String?, baseURL: String?) async throws -> [String] {
        switch provider {
        case .apple:
            try AppleIntelligence.checkAvailability()
            return [AppleIntelligence.modelName]

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
                .map { String($0.name.trimmingPrefix("models/")) }
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
        return try await perform(request)
    }

    /// Sends a request and maps HTTP failures to `ProviderError`.
    func perform(_ request: URLRequest) async throws -> Data {
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
            let message = Self.errorMessage(in: data)
            // Gemini reports a bad key as 400 "API key not valid".
            let isKeyError = status == 401 || status == 403
                || (status == 400 && message?.localizedStandardContains("API key") == true)
            if isKeyError {
                throw ProviderError.invalidKey(message)
            }
            throw ProviderError.server(status: status, message: message)
        }
        return data
    }

    /// Pulls a human-readable message out of the error shapes providers use:
    /// `{"error":{"message":…}}` (OpenAI, Anthropic, Gemini, OpenRouter), `{"detail":…}` (Mistral),
    /// `{"error":"…"}` (Ollama) and `{"message":…}`.
    static func errorMessage(in data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let error = json["error"] as? [String: Any], let message = error["message"] as? String { return message }
        if let error = json["error"] as? String { return error }
        if let detail = json["detail"] as? String { return detail }
        return json["message"] as? String
    }

    func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
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
