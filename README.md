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

Want the user's pick in your own state? Bind it:

```swift
@State private var selectedAIProvider: AIProvider?

AIProviderSettingsSection(selection: $selectedAIProvider)
```

Show which AI is in use anywhere (updates live):

```swift
CurrentAIProviderRow()                                   // "Current AI   Anthropic / claude-sonnet-5"
Text(AIProviderStore.shared.activeProvider?.displayName ?? "None")   // just the name
```

## Read the user's pick in code

```swift
let provider = AIProviderStore.shared.activeProvider     // AIProvider?, nil until one is connected
provider?.displayName                                    // "Anthropic"
provider?.rawValue                                       // "anthropic" (stable, good for saving or analytics)

if let creds = AIProviderStore.shared.activeCredentials { // model, API key, base URL
    print(creds.provider, creds.model ?? "")
}
```

React when the user switches:

```swift
@State private var selectedAIProvider: AIProvider?

AIProviderSettingsSection(selection: $selectedAIProvider)
    .onChange(of: selectedAIProvider) { _, provider in /* save, log, tell your backend */ }
```

Change it from code with `AIProviderStore.shared.selectProvider(.openAI)`. It returns
`false` if that provider isn't connected. Off the main actor, `await` these calls.
Working example: [SelectedProviderExample.swift](AI%20Providers/Examples/SelectedProviderExample.swift).

## Customize

```swift
AIProviderSettingsView(configuration: AIKitConfiguration(title: "Assistant", tint: .orange))
```

### Change the icon

```swift
AIProviderSettingsSection(icon: "brain", iconColor: .orange)
```

Title, colors, row icon, and which notes/pickers show are all optional —
see [Packages/AIKit/README.md](Packages/AIKit/README.md#customize).

## Call the AI

```swift
let reply = try await AIProviderStore.shared.send("Summarize this article: …")
```

AIKit sends it to whichever provider and model the user picked, with their key.
For a conversation, pass messages:

```swift
let reply = try await AIProviderStore.shared.send(
    [.user("Hi"), .assistant("Hello! How can I help?"), .user("Plan a trip to Lisbon")],
    system: "You are a concise travel assistant."
)
```

If nothing is connected it throws `AIKitError.notConnected`; show the settings.

More options: [Packages/AIKit/README.md](Packages/AIKit/README.md)
