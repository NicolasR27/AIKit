import Foundation
import Testing
@testable import AIKit

// Nested in NetworkTests so it inherits `.serialized` (see ChatTests).
extension NetworkTests {
@MainActor
@Suite struct WebSearchTests {
    private func credentials(_ provider: AIProvider) -> AIProviderCredentials {
        AIProviderCredentials(provider: provider, model: "m", apiKey: "key", baseURL: provider.defaultAPIBaseURL)
    }

    private func tools(_ index: Int = 0) -> [[String: Any]] {
        StubURLProtocol.bodies[index]["tools"] as? [[String: Any]] ?? []
    }

    // MARK: - Anthropic

    @Test func anthropicSearchesFetchesAndCites() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"""
            {"stop_reason":"end_turn","content":[
              {"type":"text","text":"Let me look that up."},
              {"type":"server_tool_use","id":"s1","name":"web_search","input":{"query":"swift 7"}},
              {"type":"web_search_tool_result","tool_use_id":"s1","content":[{"type":"web_search_result","url":"https://swift.org/blog","title":"Swift Blog"}]},
              {"type":"server_tool_use","id":"s2","name":"web_fetch","input":{"url":"https://swift.org/blog/swift-7"}},
              {"type":"web_fetch_tool_result","tool_use_id":"s2","content":{"type":"web_fetch_result","url":"https://swift.org/blog/swift-7","content":{"type":"document","title":"Swift 7 Released"}}},
              {"type":"text","text":"Swift 7 shipped "},
              {"type":"text","text":"in September.","citations":[{"type":"web_search_result_location","url":"https://swift.org/blog","title":"Swift Blog","cited_text":"…"}]}
            ]}
            """#)
        })

        let answer = try await client.searchWeb([.user("Is Swift 7 out?")], system: nil, credentials: credentials(.anthropic), model: "claude-opus-5")

        #expect(answer.text == "Swift 7 shipped in September.")
        #expect(answer.sources == [
            AIWebSource(title: "Swift Blog", url: URL(string: "https://swift.org/blog")!),
            AIWebSource(title: "Swift 7 Released", url: URL(string: "https://swift.org/blog/swift-7")!),
        ])
        #expect(tools().map { $0["type"] as? String } == ["web_search_20260209", "web_fetch_20260209"])
        #expect(StubURLProtocol.requests.first?.url?.absoluteString == "https://api.anthropic.com/v1/messages")
    }

    @Test(arguments: ["claude-haiku-4-5", "claude-sonnet-4-5-20250929", "claude-sonnet-4-20250514", "claude-3-7-sonnet-latest"])
    func olderAnthropicModelsGetBasicSearch(model: String) async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"stop_reason":"end_turn","content":[{"type":"text","text":"Hi"}]}"#)
        })

        _ = try await client.searchWeb([.user("Hi")], system: nil, credentials: credentials(.anthropic), model: model)

        #expect(tools().map { $0["type"] as? String } == ["web_search_20250305"])
    }

    @Test func anthropicResumesAPausedSearch() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            StubURLProtocol.requests.count == 1
                ? .init(json: #"""
                  {"stop_reason":"pause_turn","content":[{"type":"server_tool_use","id":"s1","name":"web_search","input":{"query":"q"}}]}
                  """#)
                : .init(json: #"""
                  {"stop_reason":"end_turn","content":[
                    {"type":"web_search_tool_result","tool_use_id":"s1","content":[]},
                    {"type":"text","text":"Done."}
                  ]}
                  """#)
        })

        let answer = try await client.searchWeb([.user("Q")], system: nil, credentials: credentials(.anthropic), model: "claude-opus-5")

        #expect(answer.text == "Done.")
        #expect(StubURLProtocol.requests.count == 2)
        // The paused blocks go back as the assistant turn, untouched, with no extra user message.
        let messages = try #require(StubURLProtocol.bodies[1]["messages"] as? [[String: Any]])
        #expect(messages.map { $0["role"] as? String } == ["user", "assistant"])
        let resent = try #require(messages[1]["content"] as? [[String: Any]])
        #expect(resent.first?["id"] as? String == "s1")
    }

    // MARK: - OpenAI, OpenRouter, Mistral

    @Test func openAIUsesResponsesAPIWithWebSearchTool() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"""
            {"output":[
              {"type":"web_search_call","id":"ws1","status":"completed"},
              {"type":"message","role":"assistant","content":[{"type":"output_text","text":"It's sunny.",
                "annotations":[{"type":"url_citation","url":"https://weather.example/lisbon","title":"Lisbon weather","start_index":0,"end_index":10}]}]}
            ]}
            """#)
        })

        let answer = try await client.searchWeb([.user("Weather in Lisbon?")], system: "Be brief", credentials: credentials(.openAI), model: "gpt-5.5")

        #expect(answer == AIAnswer(text: "It's sunny.", sources: [AIWebSource(title: "Lisbon weather", url: URL(string: "https://weather.example/lisbon")!)]))
        #expect(StubURLProtocol.requests.first?.url?.absoluteString == "https://api.openai.com/v1/responses")
        let body = try #require(StubURLProtocol.bodies.first)
        #expect(body["instructions"] as? String == ProviderClient.webSearchDirective + "\n\nBe brief")
        #expect(body["tool_choice"] as? String == "required")
        #expect(body["store"] as? Bool == false)
        #expect(tools().map { $0["type"] as? String } == ["web_search"])
        #expect(tools().first?["external_web_access"] as? Bool == true)
        #expect(body["input"] as? [[String: String]] == [["role": "user", "content": "Weather in Lisbon?"]])
    }

    @Test func openRouterAddsTheWebPlugin() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"""
            {"choices":[{"message":{"role":"assistant","content":"Here's the news.",
              "annotations":[{"type":"url_citation","url_citation":{"url":"https://news.example/a","title":"Story A","content":"…"}}]}}]}
            """#)
        })

        let answer = try await client.searchWeb([.user("News?")], system: nil, credentials: credentials(.openRouter), model: "openai/gpt-5.5")

        #expect(answer.sources.map(\.title) == ["Story A"])
        #expect(StubURLProtocol.requests.first?.url?.absoluteString == "https://openrouter.ai/api/v1/chat/completions")
        #expect(StubURLProtocol.bodies.first?["plugins"] as? [[String: String]] == [["id": "web"]])
    }

    @Test func mistralUsesConversationsWithWebSearchTool() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"""
            {"conversation_id":"c1","outputs":[
              {"type":"tool.execution","name":"web_search"},
              {"type":"message.output","role":"assistant","content":[
                {"type":"text","text":"Paris hosts it"},
                {"type":"tool_reference","tool":"web_search","title":"Event page","url":"https://event.example"},
                {"type":"text","text":" this year."}
              ]}
            ]}
            """#)
        })

        let answer = try await client.searchWeb([.user("Where is it?")], system: nil, credentials: credentials(.mistral), model: "mistral-medium-latest")

        #expect(answer.text == "Paris hosts it this year.")
        #expect(answer.sources == [AIWebSource(title: "Event page", url: URL(string: "https://event.example")!)])
        #expect(StubURLProtocol.requests.first?.url?.absoluteString == "https://api.mistral.ai/v1/conversations")
        #expect(StubURLProtocol.bodies.first?["store"] as? Bool == false)
        #expect(tools().map { $0["type"] as? String } == ["web_search"])
    }

    // MARK: - Gemini

    @Test func geminiGroundsWithGoogleSearchAndURLContext() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"""
            {"candidates":[{"content":{"role":"model","parts":[{"text":"The match ended 2–1."}]},
              "groundingMetadata":{"groundingChunks":[{"web":{"uri":"https://vertexaisearch.cloud.google.com/r/1","title":"bbc.com"}}]},
              "urlContextMetadata":{"urlMetadata":[
                {"retrievedUrl":"https://club.example/report","urlRetrievalStatus":"URL_RETRIEVAL_STATUS_SUCCESS"},
                {"retrievedUrl":"https://broken.example","urlRetrievalStatus":"URL_RETRIEVAL_STATUS_ERROR"}]}}]}
            """#)
        })

        let answer = try await client.searchWeb([.user("Score?")], system: nil, credentials: credentials(.gemini), model: "gemini-3.8-flash")

        #expect(answer.text == "The match ended 2–1.")
        #expect(answer.sources.map(\.title) == ["bbc.com", "club.example"])
        let toolKeys = tools().flatMap(\.keys)
        #expect(toolKeys == ["googleSearch", "urlContext"])
    }

    // MARK: - Steering

    @Test func everySearchTellsTheModelToUseTheWeb() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"stop_reason":"end_turn","content":[{"type":"text","text":"Hi"}]}"#)
        })

        _ = try await client.searchWeb([.user("Hi")], system: nil, credentials: credentials(.anthropic), model: "claude-opus-5")
        _ = try await client.searchWeb([.user("Hi")], system: "Be brief", credentials: credentials(.anthropic), model: "claude-opus-5")

        #expect(StubURLProtocol.bodies[0]["system"] as? String == ProviderClient.webSearchDirective)
        #expect(StubURLProtocol.bodies[1]["system"] as? String == ProviderClient.webSearchDirective + "\n\nBe brief")
    }

    @Test func plainChatIsNotSteered() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"content":[{"type":"text","text":"Hi"}]}"#)
        })

        _ = try await client.chat([.user("Hi")], system: "Be brief", credentials: credentials(.anthropic), model: "claude-opus-5")

        #expect(StubURLProtocol.bodies[0]["system"] as? String == "Be brief")
    }

    // MARK: - The "Search the Web" switch

    /// A connected Anthropic store whose stub answers the model list and then any chat or search.
    private func anthropicStore() async throws -> AIProviderStore {
        let store = makeTestStore([.anthropic])
        store.client = ProviderClient(session: StubURLProtocol.session { request in
            request.url?.path().hasSuffix("/models") == true
                ? .init(json: #"{"data":[{"id":"claude-opus-5"}]}"#)
                : .init(json: #"{"stop_reason":"end_turn","content":[{"type":"text","text":"Reply"}]}"#)
        })
        try await store.connect(.anthropic, apiKey: "key", baseURL: nil)
        return store
    }

    private func lastTools() -> [String]? {
        (StubURLProtocol.bodies.last?["tools"] as? [[String: Any]])?.compactMap { $0["type"] as? String }
    }

    @Test func sendSearchesByDefault() async throws {
        let store = try await anthropicStore()
        #expect(store.webSearchEnabled)

        _ = try await store.send("Write a report on Swift 7")

        #expect(lastTools() == ["web_search_20260209", "web_fetch_20260209"])
        #expect((StubURLProtocol.bodies.last?["system"] as? String)?.hasPrefix(ProviderClient.webSearchDirective) == true)
    }

    @Test func switchOffMeansPlainChat() async throws {
        let store = try await anthropicStore()
        store.webSearchEnabled = false

        _ = try await store.send("Hi", system: "Be brief")

        #expect(lastTools() == nil)
        #expect(StubURLProtocol.bodies.last?["system"] as? String == "Be brief")
    }

    @Test func explicitWebSearchOverridesTheSwitch() async throws {
        let store = try await anthropicStore()
        store.webSearchEnabled = false
        _ = try await store.send("Hi", webSearch: true)
        #expect(lastTools() == ["web_search_20260209", "web_fetch_20260209"])

        store.webSearchEnabled = true
        _ = try await store.send("Hi", webSearch: false)
        #expect(lastTools() == nil)
    }

    @Test func providersThatCantSearchJustChat() async throws {
        let store = AIProviderStore(providers: [.ollama], defaults: UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!)
        store.client = ProviderClient(session: StubURLProtocol.session { request in
            request.url?.path() == "/api/tags"
                ? .init(json: #"{"models":[{"name":"llama3"}]}"#)
                : .init(json: #"{"message":{"role":"assistant","content":"Pong"}}"#)
        })
        try await store.connect(.ollama, apiKey: nil, baseURL: nil)
        #expect(store.webSearchEnabled)

        let reply = try await store.send("Ping")

        #expect(reply == "Pong")
        #expect(StubURLProtocol.requests.last?.url?.path() == "/api/chat")
    }

    @Test func switchPersistsAcrossStoreInstances() {
        let defaults = UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!
        let first = AIProviderStore(providers: [.openAI], defaults: defaults)
        #expect(first.webSearchEnabled)
        first.webSearchEnabled = false

        let second = AIProviderStore(providers: [.openAI], defaults: defaults)
        #expect(!second.webSearchEnabled)
    }

    // MARK: - Providers without search

    @Test(arguments: [AIProvider.apple, .ollama])
    func providersWithoutSearchSaySo(provider: AIProvider) async {
        let local = AIProviderCredentials(provider: provider, model: "m", apiKey: nil, baseURL: provider.defaultAPIBaseURL)

        await #expect(throws: AIKitError.webSearchNotSupported(provider)) {
            try await ProviderClient().searchWeb([.user("Hi")], system: nil, credentials: local, model: "m")
        }
        #expect(!provider.supportsWebSearch)
    }

    @Test func storeSaysWhenItCantSearch() async throws {
        let store = AIProviderStore(providers: [.ollama], defaults: UserDefaults(suiteName: "AIKitTests.\(UUID().uuidString)")!)
        store.client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"models":[{"name":"llama3"}]}"#)
        })
        try await store.connect(.ollama, apiKey: nil, baseURL: nil)

        #expect(!store.canSearchWeb)
        await #expect(throws: AIKitError.webSearchNotSupported(.ollama)) {
            try await store.send("Hi", webSearch: true)
        }
    }

    // MARK: - Apple Intelligence's search tool

    private struct FakeEngine: AIWebSearchEngine {
        func search(_ query: String) async throws -> AIAnswer {
            AIAnswer(text: "Found: \(query)", sources: [AIWebSource(title: "Page", url: URL(string: "https://page.example")!)])
        }
    }

    @Test func appleSearchesThroughAConnectedProvider() async throws {
        let store = try await anthropicStore()
        #expect(!AIProvider.apple.supportsWebSearch)
        #expect(store.canSearchWeb(.apple))

        let relay = try #require(store.searchEngine(for: .apple) as? RelayedWebSearch)
        #expect(relay.credentials.provider == .anthropic)
        #expect(store.searchEngine(for: .anthropic) == nil)
    }

    @Test func appleCantSearchWithNothingToRelayThrough() {
        let store = makeTestStore([.apple, .ollama])
        #expect(store.searchEngine(for: .apple) == nil)
        #expect(!store.canSearchWeb(.apple))
    }

    @Test func yourOwnEngineWins() async throws {
        let store = try await anthropicStore()
        store.webSearchEngine = FakeEngine()
        #expect(store.searchEngine(for: .apple) is FakeEngine)
    }

    @Test func relayedSearchSendsOnlyTheQuery() async throws {
        let client = ProviderClient(session: StubURLProtocol.session { _ in
            .init(json: #"{"stop_reason":"end_turn","content":[{"type":"text","text":"Sunny, 21°C."}]}"#)
        })
        let relay = RelayedWebSearch(client: client, credentials: credentials(.anthropic), model: "claude-opus-5")

        let answer = try await relay.search("weather lisbon")

        #expect(answer.text == "Sunny, 21°C.")
        let body = try #require(StubURLProtocol.bodies.first)
        let messages = try #require(body["messages"] as? [[String: Any]])
        #expect(messages.count == 1)
        #expect((body["system"] as? String)?.hasSuffix(RelayedWebSearch.instructions) == true)
        #expect(tools().map { $0["type"] as? String } == ["web_search_20260209", "web_fetch_20260209"])
    }

    /// A tool with a roomy budget and a 4-characters-per-token estimate instead of the real tokenizer.
    private func tool(_ engine: any AIWebSearchEngine = FakeEngine(), budget: Int = 4_000) -> AppleWebSearchTool {
        var tool = AppleWebSearchTool(engine: engine)
        tool.measure = { ($0.count + 3) / 4 }
        tool.budget.set(budget)
        return tool
    }

    @Test func toolReturnsFindingsAndKeepsSources() async throws {
        let tool = tool()

        let output = try await tool.call(arguments: .init(query: "swift 7"))

        #expect(output == "Found: swift 7\n\nSources: Page")
        #expect(tool.log.sources == [AIWebSource(title: "Page", url: URL(string: "https://page.example")!)])
        #expect(tool.budget.remaining == 4_000 - (output.count + 3) / 4 - AppleWebSearchTool.callOverhead)
    }

    private struct LongEngine: AIWebSearchEngine {
        func search(_ query: String) async throws -> AIAnswer {
            AIAnswer(text: String(repeating: "word ", count: 400))
        }
    }

    @Test func toolTrimsResultsToWhatsLeft() async throws {
        let tool = tool(LongEngine(), budget: 300)

        let output = try await tool.call(arguments: .init(query: "q"))

        #expect((output.count + 3) / 4 <= 300 - AppleWebSearchTool.callOverhead)
        #expect(output.count > 400)
        #expect(tool.budget.remaining < AppleWebSearchTool.minimumResultTokens + AppleWebSearchTool.callOverhead)
    }

    @Test func toolStopsSearchingWhenTheContextIsFull() async throws {
        let tool = tool(budget: 100)

        let output = try await tool.call(arguments: .init(query: "q"))

        #expect(output == AppleWebSearchTool.budgetSpent)
        #expect(tool.log.sources.isEmpty)
    }

    @Test func toolOutputFitsTheOnDeviceContext() {
        let long = AppleWebSearchTool.output(for: AIAnswer(text: String(repeating: "a", count: 5_000)))
        #expect(long.count == AppleWebSearchTool.maxFindingsLength)
        #expect(AppleWebSearchTool.output(for: AIAnswer(text: " ")) == "The search found nothing relevant.")
    }

    @Test func sourcesSkipDuplicatesAndNonWebLinks() {
        let sources = AIWebSource.list([
            ("A", "https://a.example"), ("A again", "https://a.example"),
            (nil, "https://b.example/page"), ("Mail", "mailto:x@y.z"), ("Nothing", nil),
        ])
        #expect(sources == [
            AIWebSource(title: "A", url: URL(string: "https://a.example")!),
            AIWebSource(title: "b.example", url: URL(string: "https://b.example/page")!),
        ])
    }
}
}
