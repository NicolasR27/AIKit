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
                        TextField("API Key", text: $keyDraft, prompt: Text(keyPrompt))
                    } else {
                        SecureField("API Key", text: $keyDraft, prompt: Text(keyPrompt))
                    }
                }
                .secretEntry()
                .labelsHidden()

                Button(revealsKey ? "Hide Key" : "Show Key",
                       systemImage: revealsKey ? "eye.slash" : "eye",
                       action: toggleReveal)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
            }
        } header: {
            Text("API Key")
        } footer: {
            if let url = provider.keyConsoleURL {
                Link("Get your \(provider.displayName) API key", destination: url)
            }
        }
    }

    private func toggleReveal() {
        revealsKey.toggle()
    }
}
