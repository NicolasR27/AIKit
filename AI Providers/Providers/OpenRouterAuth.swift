import CryptoKit
import Foundation

/// OpenRouter's OAuth PKCE flow: the user approves in a web sheet and OpenRouter
/// mints an API key for them, so there's nothing to copy and paste.
/// https://openrouter.ai/docs/guides/overview/auth/oauth
struct OpenRouterAuth {
    static let callbackScheme = "aiproviders"

    let codeVerifier: String
    let authURL: URL

    init(keyLabel: String = "AI Providers iOS") {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        codeVerifier = Data(bytes).base64URLEncoded()

        let challenge = Data(SHA256.hash(data: Data(codeVerifier.utf8))).base64URLEncoded()

        var components = URLComponents(string: "https://openrouter.ai/auth")!
        components.queryItems = [
            URLQueryItem(name: "callback_url", value: "\(Self.callbackScheme)://oauth/openrouter"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "key_label", value: keyLabel),
        ]
        authURL = components.url!
    }

    /// Pulls `?code=` out of the callback and trades it for a user-owned API key.
    func exchange(callbackURL: URL, session: URLSession = .shared) async throws -> String {
        let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "code" }?.value
        guard let code, !code.isEmpty else {
            throw ProviderError.unavailable("OpenRouter didn't return a sign-in code. Please try again.")
        }

        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/auth/keys")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ExchangeBody(
            code: code,
            code_verifier: codeVerifier,
            code_challenge_method: "S256"
        ))

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status),
              let key = try? JSONDecoder().decode(ExchangeResponse.self, from: data).key else {
            throw ProviderError.server(status: status, message: "OpenRouter couldn't finish signing you in.")
        }
        return key
    }
}

private struct ExchangeBody: Encodable {
    let code: String
    let code_verifier: String
    let code_challenge_method: String
}

private struct ExchangeResponse: Decodable {
    let key: String
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
    }
}
