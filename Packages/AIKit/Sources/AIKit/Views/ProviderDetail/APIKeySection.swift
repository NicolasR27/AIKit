import SwiftUI

struct APIKeySection: View {
    let provider: AIProvider
    let keyPrompt: String
    @Binding var keyDraft: String
    @Binding var revealsKey: Bool

    var body: some View {
        Section {
            HStack {
                Group {
                    if revealsKey {
                        TextField(.apiKey, text: $keyDraft, prompt: Text(keyPrompt))
                    } else {
                        SecureField(.apiKey, text: $keyDraft, prompt: Text(keyPrompt))
                    }
                }
                .secretEntry()
                .labelsHidden()

                Button(revealsKey ? .hideKey : .showKey,
                       systemImage: revealsKey ? "eye.slash" : "eye",
                       action: toggleReveal)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
            }
        } header: {
            Text(.apiKey)
        } footer: {
            if let url = provider.keyConsoleURL {
                Link(.getAPIKey(provider.displayName), destination: url)
            }
        }
    }

    private func toggleReveal() {
        revealsKey.toggle()
    }
}
