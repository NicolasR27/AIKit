import SwiftUI

struct ConnectSection: View {
    let title: LocalizedStringKey
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
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if let lastVerified {
                Text("Verified \(lastVerified, format: .relative(presentation: .named)).")
            }
        }
    }
}
