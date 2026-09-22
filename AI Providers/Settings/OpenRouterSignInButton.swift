import AuthenticationServices
import SwiftUI

/// One-tap OpenRouter login: opens a secure web sheet, then saves the minted key.
struct OpenRouterSignInButton: View {
    @Environment(ProviderStore.self) private var store
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    @State private var isSigningIn = false
    @State private var errorMessage = ""
    @State private var showsError = false

    var body: some View {
        Button(action: signIn) {
            Label {
                Text(isSigningIn ? "Signing In…" : "Sign in with OpenRouter")
            } icon: {
                if isSigningIn {
                    ProgressView()
                } else {
                    Image(systemName: "person.badge.key.fill")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(AIProvider.openRouter.tint)
        .disabled(isSigningIn)
        .alert("Couldn't Sign In", isPresented: $showsError) {
        } message: {
            Text(errorMessage)
        }
    }

    private func signIn() {
        Task { await performSignIn() }
    }

    private func performSignIn() async {
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            try await store.signInWithOpenRouter { url in
                try await webAuthenticationSession.authenticate(
                    using: url,
                    callback: .customScheme(OpenRouterAuth.callbackScheme),
                    preferredBrowserSession: .shared,
                    additionalHeaderFields: [:]
                )
            }
        } catch ASWebAuthenticationSessionError.canceledLogin {
            return
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            showsError = true
        }
    }
}
