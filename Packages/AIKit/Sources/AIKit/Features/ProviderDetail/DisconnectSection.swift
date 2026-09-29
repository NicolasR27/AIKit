import SwiftUI

struct DisconnectSection: View {
    let provider: AIProvider
    let disconnect: () -> Void

    @State private var confirmsDisconnect = false

    var body: some View {
        Section {
            Button(.disconnect, role: .destructive, action: askToDisconnect)
                .confirmationDialog(.disconnectProvider(provider.displayName), isPresented: $confirmsDisconnect) {
                    Button(.disconnect, role: .destructive, action: disconnect)
                } message: {
                    Text(provider.requiresAPIKey ? .disconnectKeyMessage : .disconnectServerMessage)
                }
        }
    }

    private func askToDisconnect() {
        confirmsDisconnect = true
    }
}
