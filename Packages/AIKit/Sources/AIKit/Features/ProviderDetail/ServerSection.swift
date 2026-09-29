import SwiftUI

/// Server address for self-hosted providers (Ollama).
struct ServerSection: View {
    let provider: AIProvider
    @Binding var baseURL: String

    var body: some View {
        Section {
            TextField(.serverURL, text: $baseURL, prompt: Text(provider.defaultBaseURL ?? ""))
                .secretEntry()
                .keyboardType(.URL)
                .labelsHidden()
        } header: {
            Text(.server)
        } footer: {
            VStack(alignment: .leading) {
                Text(.ollamaFooter)
                if let url = provider.keyConsoleURL {
                    Link(.downloadOllama, destination: url)
                }
            }
        }
    }
}
