import AuthenticationServices
import Foundation
import Observation

/// State and actions for one provider's page: typing a key or server, connecting,
/// the Apple Intelligence switch, OpenRouter sign-in, and disconnecting.
@Observable
final class ProviderDetailViewModel {
    let provider: AIProvider
    @ObservationIgnored let store: AIProviderStore

    var keyDraft = ""
    var baseURLDraft: String
    var revealsKey = false

    private(set) var isWorking = false
    private(set) var errorMessage: String?
    /// Setting this starts a connection check. The view runs it in `.task(id:)`,
    /// so SwiftUI cancels it if the user leaves the page.
    private(set) var connectRequest: UUID?

    private(set) var isSigningIn = false
    var signInError: String?

    init(store: AIProviderStore, provider: AIProvider) {
        self.store = store
        self.provider = provider
        baseURLDraft = store.settings(for: provider).baseURL ?? provider.defaultBaseURL ?? ""
    }

    // MARK: - State

    var isConnected: Bool { store.isConnected(provider) }
    var lastVerified: Date? { store.settings(for: provider).lastVerified }
    var selectedModel: String? { store.settings(for: provider).selectedModel }
    var openRouterCallbackScheme: String { store.openRouterCallbackScheme }

    /// Shows the last four characters of a saved key, or an example key.
    var keyPrompt: String {
        store.maskedKey(for: provider).map { String(localized: .savedKey($0)) } ?? provider.keyPlaceholder
    }

    var canConnect: Bool {
        guard !isChecking else { return false }
        guard provider.requiresAPIKey else { return true }
        return !keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.hasStoredKey(for: provider)
    }

    var connectTitle: LocalizedStringResource {
        isConnected && keyDraft.isEmpty ? .testConnection : .connect
    }

    var showsConnectSuccess: Bool { isConnected && errorMessage == nil }

    /// A check has been asked for or is running.
    var isChecking: Bool { isWorking || connectRequest != nil }

    /// The Apple Intelligence switch. Shows on while connected or while a check runs;
    /// turning it on checks the model is available before saving, off forgets it.
    var isOnDeviceEnabled: Bool {
        get { isConnected || isChecking }
        set {
            guard newValue != isOnDeviceEnabled else { return }
            if newValue { requestConnect() } else { disconnect() }
        }
    }

    var isDefault: Bool {
        get { store.isDefault(provider) }
        set { store.setDefault(provider, newValue) }
    }

    var isShowingSignInError: Bool {
        get { signInError != nil }
        set { if !newValue { signInError = nil } }
    }

    // MARK: - Actions

    func requestConnect() {
        connectRequest = UUID()
    }

    /// Runs the check `requestConnect()` asked for. Call it from `.task(id: connectRequest)`.
    func runRequestedConnect() async {
        guard connectRequest != nil else { return }
        await connect()
        // Clear it even after a cancel, so coming back from the model picker doesn't re-run the check.
        connectRequest = nil
    }

    func disconnect() {
        store.disconnect(provider)
        keyDraft = ""
        errorMessage = nil
    }

    /// `authenticate` presents the web sheet for the given URL and returns the callback URL.
    func signInWithOpenRouter(authenticate: (URL) async throws -> URL) async {
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            try await store.signInWithOpenRouter(authenticate: authenticate)
        } catch ASWebAuthenticationSessionError.canceledLogin {
            // The user closed the sign-in sheet.
            return
        } catch is CancellationError {
            return
        } catch {
            signInError = error.localizedDescription
        }
    }

    func makeModelPickerViewModel() -> ModelPickerViewModel {
        ModelPickerViewModel(store: store, provider: provider)
    }

    // MARK: - Private

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
