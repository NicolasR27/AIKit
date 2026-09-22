# AIKit

Let users connect their own AI account (OpenAI, Anthropic, Gemini, Mistral,
OpenRouter, Ollama) from a native iOS settings screen. iOS 26+.

## Install

1. In Xcode: **File ▸ Add Package Dependencies…**
2. Paste this repo's URL and add **AIKit** to your app target.

## Use (one line)

```swift
import AIKit

AIProviderSettingsView()          // full settings screen
```

Already have a Settings screen? Add one row instead:

```swift
AIProviderSettingsSection()       // inside your Form, in a NavigationStack
```

## Customize

```swift
AIProviderSettingsView(configuration: AIKitConfiguration(title: "Assistant", tint: .orange))
```

Title, colors, row icon, and which notes/pickers show are all optional —
see [Packages/AIKit/README.md](Packages/AIKit/README.md#customize).

## Call the AI

```swift
// From async code (e.g. your networking service), use await:
if let ai = await AIProviderStore.shared.activeCredentials {
    ai.provider   // .openAI, .anthropic, …
    ai.model      // model the user picked
    ai.apiKey     // user's key (from Keychain)
    ai.baseURL    // API root to send requests to
}
```

More options: [Packages/AIKit/README.md](Packages/AIKit/README.md)
