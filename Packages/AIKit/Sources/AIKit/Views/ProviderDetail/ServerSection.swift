import SwiftUI

/// Server address for self-hosted providers (Ollama).
struct ServerSection: View {
    let provider: AIProvider
    @Binding var baseURL: String

    var body: some View {
        Section {
            TextField("Server URL", text: $baseURL, prompt: Text(provider.defaultBaseURL ?? ""))
                .secretEntry()
                .keyboardType(.URL)
                .labelsHidden()
        } header: {
            Text("Server")
        } footer: {
            VStack(alignment: .leading) {
                Text("Run Ollama on a computer on your network. From another device, use that computer's local IP address instead of localhost.")
                if let url = provider.keyConsoleURL {
                    Link("Download Ollama", destination: url)
                }
            }
        }
    }
}
