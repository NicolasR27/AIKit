import SwiftUI

/// One-tap OpenRouter login: the button opens a secure web sheet, then the minted key is saved.
struct OpenRouterSignInSection: View {
    let isSigningIn: Bool
    let signIn: () -> Void

    var body: some View {
        Section {
            Button(action: signIn) {
                Label {
                    Text(isSigningIn ? .signingIn : .signInWithOpenRouter)
                } icon: {
                    if isSigningIn {
                        ProgressView()
                    } else {
                        Image(systemName: "person.badge.key.fill")
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AIProvider.openRouter.tint)
            .disabled(isSigningIn)
        } footer: {
            Text(.openRouterFooter)
        }
    }
}
