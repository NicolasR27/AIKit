import SwiftUI

struct ProviderDetailView: View {
    let store: AIProviderStore
    let provider: AIProvider
    let configuration: AIKitConfiguration

    @State private var keyDraft = ""
    @State private var baseURLDraft = ""
    @State private var revealsKey = false
    @State private var isWorking = false
    @State private var errorMessage: String?
    /// Mirrors `showsOnDeviceOn`; the user flipping it connects or disconnects Apple Intelligence.
    @State private var isOnDeviceEnabled = false
    /// Setting this starts a connection check; `.task(id:)` cancels it if the user leaves.
    @State private var connectRequest: UUID?

    private var isConnected: Bool { store.isConnected(provider) }
    /// The toggle shows on while connected, and while a connection check is running.
    private var showsOnDeviceOn: Bool { isConnected || isWorking }

    var body: some View {
        Form {
            ProviderHeader(provider: provider, configuration: configuration)

            if provider == .openRouter, !isConnected, configuration.showsOpenRouterSignIn {
                OpenRouterSignInSection(store: store)
            }

            if provider.requiresAPIKey {
                APIKeySection(provider: provider, keyPrompt: keyPrompt, keyDraft: $keyDraft, revealsKey: $revealsKey)
            }
            if provider.usesCustomBaseURL {
                ServerSection(provider: provider, baseURL: $baseURLDraft)
            }

            if provider.isOnDevice {
                OnDeviceToggleSection(
                    provider: provider,
                    isOn: $isOnDeviceEnabled,
                    isWorking: isWorking,
                    errorMessage: errorMessage
                )
                .onChange(of: showsOnDeviceOn, initial: true) { _, isOn in
                    isOnDeviceEnabled = isOn
                }
                .onChange(of: isOnDeviceEnabled) { _, isOn in
                    // Ignore the sync above; only react to the user flipping the switch.
                    guard isOn != showsOnDeviceOn else { return }
                    setEnabled(isOn)
                }
            } else {
                ConnectSection(
                    title: connectTitle,
                    isWorking: isWorking,
                    isEnabled: canConnect,
                    showsSuccess: isConnected && errorMessage == nil,
                    errorMessage: errorMessage,
                    lastVerified: store.settings(for: provider).lastVerified,
                    connect: requestConnect
                )
            }

            if isConnected {
                if !provider.isOnDevice {
                    ModelSection(store: store, provider: provider)
                }
                DefaultProviderSection(store: store, provider: provider)
                if !provider.isOnDevice {
                    DisconnectSection(provider: provider, disconnect: disconnect)
                }
            }
        }
        .navigationTitle(provider.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .tint(configuration.tint)
        .onAppear(perform: loadDrafts)
        .task(id: connectRequest) {
            guard connectRequest != nil else { return }
            await connect()
            // Clear it even after a cancel, so coming back from the model picker doesn't re-run the check.
            connectRequest = nil
        }
    }

    private var keyPrompt: String {
        store.maskedKey(for: provider).map { String(localized: "Saved key \($0)") } ?? provider.keyPlaceholder
    }

    private var canConnect: Bool {
        guard provider.requiresAPIKey else { return true }
        return !keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.hasStoredKey(for: provider)
    }

    private var connectTitle: LocalizedStringKey {
        isConnected && keyDraft.isEmpty ? "Test Connection" : "Connect"
    }

    private func loadDrafts() {
        if baseURLDraft.isEmpty {
            baseURLDraft = store.settings(for: provider).baseURL ?? provider.defaultBaseURL ?? ""
        }
    }

    private func requestConnect() {
        connectRequest = UUID()
    }

    /// Turning the toggle on checks the model is available before saving; off forgets it.
    private func setEnabled(_ isOn: Bool) {
        if isOn {
            requestConnect()
        } else {
            disconnect()
        }
    }

    private func disconnect() {
        store.disconnect(provider)
        keyDraft = ""
        errorMessage = nil
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

#Preview {
    NavigationStack {
        ProviderDetailView(store: AIProviderStore(), provider: .anthropic, configuration: AIKitConfiguration())
    }
}
