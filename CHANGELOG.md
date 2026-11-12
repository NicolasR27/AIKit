# Changelog

What changed in each AIKit release. Newest first.

## Unreleased

### Added
- **Plain row icon.** `AIKitConfiguration(rowIconStyle: .plain)` draws the "AI Providers"
  row's symbol without the colored tile, in your app's tint, so it matches plain `Label` rows
  like `Label("Siri", systemImage: "waveform")`. The default is still `.tile`.

## 1.1.2 — 2026-11-08

### Fixed
- **No more raw `<cite index="2-4">…</cite>` tags in answers.** Claude sometimes writes its
  citations inline as markup instead of returning them separately. AIKit now strips the tags
  from web search replies and keeps the cited words; a plain HTML `<cite>` is left alone. Sources still come back in
  `AIAnswer.sources`.

## 1.1.1 — 2026-11-06

### Fixed
- **Apple Intelligence no longer fails with "Provided 8,595 tokens, but the maximum allowed is
  8,192."** Everything sent to the on-device model now has to fit its 8,192-token context: the
  instructions, the conversation, the search results and the reply. AIKit now counts tokens
  with Apple's own tokenizer and keeps the total under the limit:
  - Room is kept free for the reply, and the oldest chat turns are dropped if the conversation
    is too long.
  - Search results are trimmed to the space that's left; once it's used up, the model answers
    from what it already found instead of searching again (and paying for it).
  - If it still overflows, AIKit retries once with more room for the reply, then shows a
    readable, translated message instead of raw token counts.

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
