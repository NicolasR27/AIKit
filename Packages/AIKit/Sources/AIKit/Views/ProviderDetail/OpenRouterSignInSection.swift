import SwiftUI

struct OpenRouterSignInSection: View {
    let store: AIProviderStore

    var body: some View {
        Section {
            OpenRouterSignInButton(store: store)
        } footer: {
            Text(.openRouterFooter)
        }
    }
}
