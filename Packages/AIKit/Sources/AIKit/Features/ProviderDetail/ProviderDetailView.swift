import AuthenticationServices
import SwiftUI

struct ProviderDetailView: View {
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    let configuration: AIKitConfiguration
    @State private var viewModel: ProviderDetailViewModel

    private var provider: AIProvider { viewModel.provider }

    private var showsOpenRouterSignIn: Bool {
        provider == .openRouter && !viewModel.isConnected && configuration.showsOpenRouterSignIn
    }

    init(store: AIProviderStore, provider: AIProvider, configuration: AIKitConfiguration) {
        _viewModel = State(initialValue: ProviderDetailViewModel(store: store, provider: provider))
        self.configuration = configuration
    }

    var body: some View {
        Form {
            ProviderHeader(provider: provider, configuration: configuration)

            if showsOpenRouterSignIn {
                OpenRouterSignInSection(isSigningIn: viewModel.isSigningIn, signIn: signInWithOpenRouter)
            }

            if provider.requiresAPIKey {
                APIKeySection(
                    provider: provider,
                    keyPrompt: viewModel.keyPrompt,
                    keyDraft: $viewModel.keyDraft,
                    revealsKey: $viewModel.revealsKey
                )
            }
            if provider.usesCustomBaseURL {
                ServerSection(provider: provider, baseURL: $viewModel.baseURLDraft)
            }

            if provider.isOnDevice {
                OnDeviceToggleSection(
                    provider: provider,
                    isOn: $viewModel.isOnDeviceEnabled,
                    isWorking: viewModel.isChecking,
                    errorMessage: viewModel.errorMessage
                )
            } else {
                ConnectSection(
                    title: viewModel.connectTitle,
                    isWorking: viewModel.isChecking,
                    isEnabled: viewModel.canConnect,
                    showsSuccess: viewModel.showsConnectSuccess,
                    errorMessage: viewModel.errorMessage,
                    lastVerified: viewModel.lastVerified,
                    connect: viewModel.requestConnect
                )
            }

            if viewModel.isConnected {
                ConnectedSections(
                    provider: provider,
                    selectedModel: viewModel.selectedModel,
                    isDefault: $viewModel.isDefault,
                    disconnect: viewModel.disconnect
                ) {
                    ModelPickerView(viewModel: viewModel.makeModelPickerViewModel())
                }
            }
        }
        .navigationTitle(provider.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .tint(configuration.tint)
        .task(id: viewModel.connectRequest) {
            await viewModel.runRequestedConnect()
        }
        .alert(.couldntSignIn, isPresented: $viewModel.isShowingSignInError) {
        } message: {
            Text(viewModel.signInError ?? "")
        }
    }

    private func signInWithOpenRouter() {
        let scheme = viewModel.openRouterCallbackScheme
        Task {
            await viewModel.signInWithOpenRouter { url in
                try await webAuthenticationSession.authenticate(
                    using: url,
                    callback: .customScheme(scheme),
                    preferredBrowserSession: .shared,
                    additionalHeaderFields: [:]
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProviderDetailView(store: AIProviderStore(), provider: .anthropic, configuration: AIKitConfiguration())
    }
}
