import Foundation
import Testing
@testable import AIKit

// Nested in NetworkTests so it inherits `.serialized`: every stubbed-network test shares
// StubURLProtocol's static handler and must not run in parallel with another.
extension NetworkTests {
@MainActor
@Suite struct ChatTests {
    private func credentials(_ provider: AIProvider, key: String? = "key") -> AIProviderCredentials {
        AIProviderCredentials(provider: provider, model: "m", apiKey: key, baseURL: provider.defaultAPIBaseURL)
    }

    @Test(arguments: [AIProvider.openAI, .mistral, .openRouter])
    func openAICompatibleProviders(provider: AIProvider) async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"choices":[{"message":{"role":"assistant","content":"Hello!"}}]}"#)
        })

        let reply = try await client.chat([.user("Hi")], system: "Be brief", credentials: credentials(provider), model: "m")

        #expect(reply == "Hello!")
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.url == provider.defaultAPIBaseURL?.appending(path: "chat/completions"))
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer key")
        let messages = try #require(StubURLProtocol.bodies.first?["messages"] as? [[String: String]])
        #expect(messages == [["role": "system", "content": "Be brief"], ["role": "user", "content": "Hi"]])
    }

    @Test func anthropicUsesMessagesAPI() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"content":[{"type":"text","text":"Hel"},{"type":"text","text":"lo"}]}"#)
        })

        let reply = try await client.chat([.user("Hi")], system: "Be brief", credentials: credentials(.anthropic), model: "m")

        #expect(reply == "Hello")
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "key")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        let body = try #require(StubURLProtocol.bodies.first)
        #expect(body["system"] as? String == "Be brief")
        #expect(body["max_tokens"] as? Int == 4096)
    }

    @Test func geminiUsesGenerateContentAndModelRole() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"candidates":[{"content":{"role":"model","parts":[{"text":"Hi there"}]}}]}"#)
        })

        let reply = try await client.chat(
            [.user("Hi"), .assistant("Hello"), .user("How are you?")],
            system: nil,
            credentials: credentials(.gemini),
            model: "gemini-pro"
        )

        #expect(reply == "Hi there")
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.url?.absoluteString == "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent")
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "key")
        let contents = try #require(StubURLProtocol.bodies.first?["contents"] as? [[String: Any]])
        #expect(contents.map { $0["role"] as? String } == ["user", "model", "user"])
        #expect(StubURLProtocol.bodies.first?["systemInstruction"] == nil)
    }

    @Test func ollamaUsesChatWithoutStreaming() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"message":{"role":"assistant","content":"Local reply"}}"#)
        })
        let local = AIProviderCredentials(provider: .ollama, model: "llama3", apiKey: nil,
                                          baseURL: URL(string: "http://10.0.0.5:11434"))

        let reply = try await client.chat([.user("Hi")], system: nil, credentials: local, model: "llama3")

        #expect(reply == "Local reply")
        #expect(StubURLProtocol.requests.first?.url?.absoluteString == "http://10.0.0.5:11434/api/chat")
        #expect(StubURLProtocol.bodies.first?["stream"] as? Bool == false)
    }

    @Test func emptyReplyThrows() async {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"choices":[{"message":{"role":"assistant","content":""}}]}"#)
        })

        await #expect(throws: AIKitError.emptyResponse) {
            try await client.chat([.user("Hi")], system: nil, credentials: credentials(.openAI), model: "m")
        }
    }

    // MARK: - Error shapes seen from the real APIs

    @Test func mistralDetailErrorIsReadable() async {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(status: 401, json: #"{"detail":"Invalid API Key"}"#)
        })

        await #expect {
            try await client.chat([.user("Hi")], system: nil, credentials: credentials(.mistral), model: "m")
        } throws: { error in
            error.localizedDescription == "This API key was rejected (Invalid API Key)."
        }
    }

    @Test func gemini400BadKeyCountsAsRejectedKey() async {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(status: 400, json: #"{"error":{"code":400,"message":"API key not valid. Please pass a valid API key.","status":"INVALID_ARGUMENT"}}"#)
        })

        await #expect {
            try await client.chat([.user("Hi")], system: nil, credentials: credentials(.gemini), model: "m")
        } throws: { error in
            guard case ProviderError.invalidKey = error else { return false }
            return true
        }
    }

    @Test func ollamaStringErrorIsReadable() async {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(status: 404, json: #"{"error":"model 'nope' not found"}"#)
        })
        let local = AIProviderCredentials(provider: .ollama, model: "nope", apiKey: nil,
                                          baseURL: URL(string: "http://localhost:11434"))

        await #expect {
            try await client.chat([.user("Hi")], system: nil, credentials: local, model: "nope")
        } throws: { error in
            error.localizedDescription == "model 'nope' not found"
        }
    }

    // MARK: - AIProviderStore.send

    @Test func sendWithoutConnectionThrowsNotConnected() async {
        let store = AIProviderStore(providers: [.ollama], defaults: UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!)

        await #expect(throws: AIKitError.notConnected) {
            try await store.send("Hi")
        }
    }

    @Test func sendUsesActiveProviderAndSelectedModel() async throws {
        let store = AIProviderStore(providers: [.ollama], defaults: UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!)
        store.client = ProviderClient(session: StubURLProtocol.session { request in
            request.url?.path() == "/api/tags"
                ? .init(json: #"{"models":[{"name":"llama3"},{"name":"qwen"}]}"#)
                : .init(json: #"{"message":{"role":"assistant","content":"Pong"}}"#)
        })
        try await store.connect(.ollama, apiKey: nil, baseURL: nil)
        store.selectModel("qwen", for: .ollama)

        let reply = try await store.send("Ping", system: "Answer in one word")

        #expect(reply == "Pong")
        let chatBody = try #require(StubURLProtocol.bodies.last)
        #expect(chatBody["model"] as? String == "qwen")
    }
}
}
