import SwiftUI

struct OpenRouterSignInSection: View {
    let store: AIProviderStore

    var body: some View {
        Section {
            OpenRouterSignInButton(store: store)
        } footer: {
            Text("Creates a key in your OpenRouter account automatically. Or paste an existing key below.")
        }
    }
}
