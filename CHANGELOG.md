# Changelog

What changed in each AIKit release. Newest first.

## 1.1.0 — 2026-11-06

### Added
- **Apple Intelligence can search the web.** The on-device model gets a `searchWeb` tool
  (Foundation Models tool calling). It decides when to look something up, the tool runs the
  search, and the model answers from the results. Links come back in `answer.sources`.
- By default the tool hands just the search query (never the conversation) to another
  connected provider that can search, such as OpenAI or Claude. No setup needed.
- `AIWebSearchEngine` protocol and `AIProviderStore.webSearchEngine`, to use your own search
  API (Tavily, Brave, your server) instead.

### Changed
- `AIProviderStore.canSearchWeb` is now `true` for Apple Intelligence when it has somewhere
  to search. `AIProvider.supportsWebSearch` is unchanged: it still means "searches by itself".
- `send` with the "Search the Web" switch on now searches with Apple Intelligence too, when it can.
- `AIKitError.webSearchNotSupported` for Apple Intelligence now only happens when there's no
  `webSearchEngine` and no other connected provider that can search.

## 1.0.0 — 2026-11-05

First tagged release.

- Bring-your-own-key settings screen (`AIProviderSettingsView`) and an embeddable row
  (`AIProviderSettingsSection`) for OpenAI, Anthropic, Google Gemini, Mistral, OpenRouter,
  Ollama and Apple Intelligence (on-device).
- Keys stored in the Keychain; model picker filled from each provider's live model list.
- One-tap "Sign in with OpenRouter".
- `AIProviderStore.send` chat API for every provider, with photos (`images:`).
- Live web search (`webSearch:` / `searchWeb`) on OpenAI, Anthropic, Gemini, Mistral and
  OpenRouter, on by default with a "Search the Web" switch in settings.
- `CurrentAIProviderRow`, `selectProvider(_:)` and a selection binding for picking the provider in code.
- Customizable titles, tint, row icon and provider icons via `AIKitConfiguration`.
- Translated into English, Spanish, Italian, German and French.
