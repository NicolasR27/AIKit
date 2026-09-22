import SwiftUI

struct DisconnectSection: View {
    let provider: AIProvider
    let disconnect: () -> Void

    @State private var confirmsDisconnect = false

    var body: some View {
        Section {
            Button("Disconnect", role: .destructive, action: askToDisconnect)
                .confirmationDialog("Disconnect \(provider.displayName)?", isPresented: $confirmsDisconnect) {
                    Button("Disconnect", role: .destructive, action: disconnect)
                } message: {
                    Text(provider.requiresAPIKey
                         ? "Your saved key will be removed from this device."
                         : "Your saved server and model will be removed from this device.")
                }
        }
    }

    private func askToDisconnect() {
        confirmsDisconnect = true
    }
}
