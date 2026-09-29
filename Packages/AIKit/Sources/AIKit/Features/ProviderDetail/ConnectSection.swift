import SwiftUI

struct ConnectSection: View {
    let title: LocalizedStringResource
    let isWorking: Bool
    let isEnabled: Bool
    let showsSuccess: Bool
    let errorMessage: String?
    let lastVerified: Date?
    let connect: () -> Void

    var body: some View {
        Section {
            Button(action: connect) {
                HStack {
                    Text(title)
                    Spacer()
                    if isWorking {
                        ProgressView()
                            .controlSize(.small)
                    } else if showsSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                    }
                }
            }
            .disabled(isWorking || !isEnabled)
        } footer: {
            if let errorMessage {
                ErrorLabel(message: errorMessage)
            } else if let lastVerified {
                Text(.verified(lastVerified))
            }
        }
    }
}
