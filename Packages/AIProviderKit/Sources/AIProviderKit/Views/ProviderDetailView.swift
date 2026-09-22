import SwiftUI

struct ProviderDetailView: View {
    @Environment(AIProviderStore.self) private var store
    let provider: AIProvider

    @State private var keyDraft = ""
    @State private var baseURLDraft = ""
    @State private var revealsKey = false
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var confirmsDisconnect = false
    @State private var connectTask: Task<Void, Never>?

    private var isConnected: Bool { store.isConnected(provider) }
    private var settings: ProviderSettings { store.settings(for: provider) }

    var body: some View {
        Form {
            header

            if provider == .openRouter, !isConnected {
                Section {
                    OpenRouterSignInButton()
                } footer: {
                    Text("Creates a key in your OpenRouter account automatically. Or paste an existing key below.")
                }
            }

            if provider.requiresAPIKey {
                keySection
            }
            if provider.usesCustomBaseURL {
                serverSection
            }

            connectSection

            if isConnected {
                modelSection
                defaultSection
                disconnectSection
            }
        }
        .navigationTitle(provider.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            baseURLDraft = settings.baseURL ?? provider.defaultBaseURL ?? ""
        }
        .onDisappear {
            connectTask?.cancel()
            connectTask = nil
        }
        .confirmationDialog("Disconnect \(provider.displayName)?", isPresented: $confirmsDisconnect) {
            Button("Disconnect", role: .destructive) {
                store.disconnect(provider)
                keyDraft = ""
            }
        } message: {
            Text("Your saved key will be removed from this device.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        Section {
            VStack(spacing: 10) {
                ProviderIcon(provider: provider, size: 60)
                Text(provider.displayName).font(.title2.bold())
                Text(provider.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var keySection: some View {
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

                Button {
                    revealsKey.toggle()
                } label: {
                    Image(systemName: revealsKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(revealsKey ? "Hide key" : "Show key")
            }
        } header: {
            Text("API Key")
        } footer: {
            if let url = provider.keyConsoleURL {
                Link("Get a \(provider.displayName) API key", destination: url)
            }
        }
    }

    private var serverSection: some View {
        Section {
            TextField("Server URL", text: $baseURLDraft, prompt: Text(provider.defaultBaseURL ?? ""))
                .secretEntry()
                .labelsHidden()
        } header: {
            Text("Server")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Run Ollama on a computer on your network. From another device, use that computer's local IP address instead of localhost.")
                if let url = provider.keyConsoleURL {
                    Link("Download Ollama", destination: url)
                }
            }
        }
    }

    private var connectSection: some View {
        Section {
            Button {
                connectTask = Task { await connect() }
            } label: {
                HStack {
                    Text(connectTitle)
                    Spacer()
                    if isWorking {
                        ProgressView().controlSize(.small)
                    } else if isConnected, errorMessage == nil {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
            }
            .disabled(isWorking || !canConnect)
        } footer: {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if let verified = settings.lastVerified {
                Text("Verified \(verified.formatted(.relative(presentation: .named))).")
            }
        }
    }

    private var modelSection: some View {
        Section("Model") {
            NavigationLink {
                ModelPickerView(provider: provider)
            } label: {
                LabeledContent("Model", value: settings.selectedModel ?? "None")
            }
        }
    }

    private var defaultSection: some View {
        Section {
            Toggle("Use as Default", isOn: Binding(
                get: { store.activeProvider == provider },
                set: { isOn in
                    if isOn {
                        store.activeProvider = provider
                    } else if store.activeProvider == provider {
                        store.activeProvider = nil
                    }
                }
            ))
        }
    }

    private var disconnectSection: some View {
        Section {
            Button("Disconnect", role: .destructive) {
                confirmsDisconnect = true
            }
        }
    }

    // MARK: - Helpers

    private var keyPrompt: String {
        store.maskedKey(for: provider).map { "Saved key \($0)" } ?? provider.keyPlaceholder
    }

    private var canConnect: Bool {
        guard provider.requiresAPIKey else { return true }
        return !keyDraft.trimmingCharacters(in: .whitespaces).isEmpty || store.hasStoredKey(for: provider)
    }

    private var connectTitle: String {
        isConnected && keyDraft.isEmpty ? "Test Connection" : "Connect"
    }

    private func connect() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await store.connect(provider, apiKey: keyDraft, baseURL: baseURLDraft)
            keyDraft = ""
            revealsKey = false
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension View {
    /// Keys and URLs shouldn't be autocorrected or capitalized.
    func secretEntry() -> some View {
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }
}

#Preview {
    NavigationStack {
        ProviderDetailView(provider: .anthropic)
    }
    .environment(AIProviderStore())
}
