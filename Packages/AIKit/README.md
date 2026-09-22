# AIKit

Drop-in "bring your own key" settings for iOS apps. Users connect their own
OpenAI, Anthropic, Google Gemini, Mistral, OpenRouter or Ollama account, so they
pay the provider for usage instead of you.

- Settings-app style screen, keys verified against the provider before saving
- Keys stored in the Keychain (this device only), never in UserDefaults
- Searchable model picker filled from the provider's live model list
- One-tap **Sign in with OpenRouter** (OAuth PKCE) for access to every lab's models with one key
- iOS 26+, Swift 6, no third-party dependencies

## Install

**Local package:** drag the `AIKit` folder into your Xcode project, then add
`AIKit` under your target's *Frameworks, Libraries, and Embedded Content*.

**From git:** File ▸ Add Package Dependencies… and point at the repo containing this package.

## Use it (3 steps)

**1. Create the store once**

```swift
import AIKit
import SwiftUI

@main struct MyApp: App {
    @State private var providers = AIProviderStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(providers)
        }
    }
}
```

**2. Show the settings**, whichever way fits your app:

```swift
// As a sheet, tab or root screen (brings its own NavigationStack)
.sheet(isPresented: $showsAISettings) {
    AIProviderSettingsView(store: providers)
}

// One row inside your existing settings Form: "AI Providers · OpenAI ›"
Form {
    AccountSection()
    AIProviderSettingsSection(store: providers)
}

// Or push the full form from your own link (uses your NavigationStack)
NavigationLink("AI Providers") {
    AIProviderSettingsForm(store: providers)
}
```

`AIProviderSettingsSection` and `AIProviderSettingsForm` must sit inside a
`NavigationStack`; `AIProviderSettingsView` brings its own.

**3. Read credentials when you make a request**

`AIProviderStore` lives on the main actor. From SwiftUI or other `@MainActor`
code read it directly; from anywhere else, `await` it.

```swift
guard let credentials = await AIProviderStore.shared.activeCredentials,
      let model = credentials.model,
      let baseURL = credentials.baseURL else {
    // Nothing connected yet: show the settings.
    return
}

// credentials.provider → .openAI, .anthropic, .gemini, .mistral, .openRouter, .ollama
// credentials.apiKey   → the user's key (nil for Ollama)
// credentials.baseURL  → API root, e.g. https://openrouter.ai/api/v1
```

OpenAI, Mistral, OpenRouter and Ollama (`/v1`) all accept the same OpenAI-style
`POST {baseURL}/chat/completions` with `Authorization: Bearer <key>`. Anthropic
uses `POST {baseURL}/messages` with `x-api-key` and `anthropic-version: 2023-06-01`.
Gemini uses `POST {baseURL}/models/{model}:generateContent` with `x-goog-api-key`.

## Customize

Pass an `AIKitConfiguration` to any of the three views. Every property has a default,
so set only what you want to change:

```swift
AIProviderSettingsSection(configuration: AIKitConfiguration(
    title: "Assistant",          // list title
    tint: .orange,               // buttons, links, toggles (nil = your app's tint)
    rowTitle: "Assistant",       // the row in your Settings
    rowSymbol: "brain",          // SF Symbol in the row's icon tile
    rowTint: .orange,            // icon tile color
    showsDefaultProviderPicker: true,
    showsOpenRouterSignIn: true,
    billingNote: nil,            // nil hides the billing footer
    privacyNote: nil             // nil hides the Keychain note
))
```

Which providers appear (and in what order) is set on the store — see below.

## Options

```swift
AIProviderStore(
    providers: [.openRouter, .openAI, .anthropic], // which providers to show, in order
    openRouterCallbackScheme: "myapp",             // OAuth return scheme; no Info.plist entry needed
    openRouterKeyLabel: "MyApp iOS",               // label on the key in the user's OpenRouter dashboard
    defaults: .standard                            // where non-secret settings are saved
)
```

Other API on the store:

| API | Purpose |
| --- | --- |
| `activeProvider` | The provider the user chose as default (read/write) |
| `connectedProviders` | Every provider with verified credentials |
| `isConnected(_:)` | Whether a provider is set up |
| `credentials(for:)` | Credentials for a specific provider |
| `disconnectAll()` | Wipe all keys and settings, e.g. on sign-out |

## Ollama only: allow local HTTP

Ollama runs on plain `http://` on the user's network, which App Transport Security
blocks. If you offer `.ollama`, add this to your app's Info.plist:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
<key>NSLocalNetworkUsageDescription</key>
<string>Connect to Ollama running on a computer on your network.</string>
```

Leave `.ollama` out of `providers` and you can skip this.

## Tests

```sh
cd Packages/AIKit
xcodebuild test -scheme AIKit -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

Network calls are stubbed, and store tests use Ollama so they never touch the Keychain.
