import Foundation

/// The JSON-over-HTTP plumbing every provider backend shares: timeouts, auth headers,
/// and turning each provider's error shape into a `ProviderError`.
struct HTTPClient {
    let session: URLSession

    /// Listing models should be quick; a slow answer usually means a wrong address.
    func get(_ url: URL, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 15)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return try await perform(request)
    }

    /// Generation can take a while on large models.
    func post(_ url: URL, body: some Encodable, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ProviderError.server(status: 200, message: String(localized: .unexpectedResponseError))
        }
    }

    /// Sends a request and maps HTTP failures to `ProviderError`.
    private func perform(_ request: URLRequest) async throws -> Data {
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
}

extension HTTPClient {
    static func bearer(_ key: String) -> [String: String] {
        ["Authorization": "Bearer \(key)"]
    }
}
