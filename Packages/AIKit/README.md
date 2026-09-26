# AIKit

Drop-in "bring your own key" settings for iOS apps. Users connect their own
OpenAI, Anthropic, Google Gemini, Mistral, OpenRouter or Ollama account, so they
pay the provider for usage instead of you.

- Settings-app style screen, keys verified against the provider before saving
- Keys stored in the Keychain (this device only), never in UserDefaults
- Searchable model picker filled from the provider's live model list
- One-tap **Sign in with OpenRouter** (OAuth PKCE) for access to every lab's models with one key
- iOS 27+, Swift 6, no third-party dependencies

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

**3. Send prompts**

```swift
// Uses the user's default provider, model and key.
let reply = try await AIProviderStore.shared.send("Write a haiku about Lisbon")

// Conversations, a system prompt, or a specific connected provider:
let answer = try await AIProviderStore.shared.send(
    [.user("Hi"), .assistant("Hello!"), .user("What's 2+2?")],
    system: "Answer briefly.",
    provider: .anthropic
)
```

```swift
// Photos: pass image bytes (HEIC/JPEG/PNG; resized to 1568 px and sent as JPEG).
let watch = try await AIProviderStore.shared.send("What watch is this?", images: [photoData])
```

Errors have a user-readable `localizedDescription`. `AIKitError.notConnected` and
`.noModelSelected` mean the user needs to finish setup, so show the settings.

`AIProviderStore` lives on the main actor: from non-main code, `await` it
(`try await AIProviderStore.shared.send(…)` already does).

Replies arrive in one piece (no streaming yet). Each provider is called with its own API:

| Provider | Endpoint |
| --- | --- |
| OpenAI, Mistral, OpenRouter | `POST /chat/completions` |
| Anthropic | `POST /v1/messages` |
| Google Gemini | `POST /models/{model}:generateContent` |
| Ollama | `POST /api/chat` |
| Apple Intelligence | On-device via Foundation Models (no key, turned on with a switch) |

Need raw access instead? `AIProviderStore.shared.activeCredentials` gives you the
provider, model, key and API base URL to build your own requests.

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

### Change the icons

Put this in **your app**, in the file where you show AIKit (e.g. `SettingsView.swift`,
or your `App` file if AIKit is the whole screen). You don't edit anything inside AIKit.

**The "AI Providers" row** in your Settings:

```swift
AIProviderSettingsSection(icon: "brain", iconColor: .orange)
```

**The provider icons** (OpenAI, Anthropic, …) on every AIKit screen:

```swift
var config = AIKitConfiguration()
config.providerIcons = [.openAI: "bolt", .anthropic: "leaf"]       // SF Symbol names
config.providerIconColors = [.openAI: .teal, .anthropic: .brown]  // tile colors

AIProviderSettingsSection(configuration: config)   // or AIProviderSettingsView(configuration: config)
```

Leave a provider out and it keeps its default icon. Icon names come from Apple's free
**SF Symbols** app.

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

To also run a real round-trip against Ollama on your Mac (`ollama pull smollm:135m` first):

```sh
TEST_RUNNER_AIKIT_LIVE_OLLAMA=1 xcodebuild test -scheme AIKit -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

And against the cloud providers with your own keys (each runs only if its key is set;
it lists models, then sends one tiny prompt to a small model):

```sh
TEST_RUNNER_OPENAI_API_KEY=sk-… \
TEST_RUNNER_ANTHROPIC_API_KEY=sk-ant-… \
TEST_RUNNER_GEMINI_API_KEY=AIza… \
TEST_RUNNER_MISTRAL_API_KEY=… \
TEST_RUNNER_OPENROUTER_API_KEY=sk-or-… \
xcodebuild test -scheme AIKit -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  | grep -E "replied|✘|TEST"
```

Pin a model with e.g. `TEST_RUNNER_OPENAI_MODEL=…`.
