import SwiftUI

/// On/off switch for Apple Intelligence, which needs no key or server.
struct OnDeviceToggleSection: View {
    let provider: AIProvider
    @Binding var isOn: Bool
    let isWorking: Bool
    let errorMessage: String?

    var body: some View {
        Section {
            Toggle(isOn: $isOn) {
                HStack {
                    Text(.useProvider(provider.displayName))
                    if isWorking {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .disabled(isWorking)
        } footer: {
            if let errorMessage {
                ErrorLabel(message: errorMessage)
            } else {
                Text(.onDeviceFooter)
            }
        }
    }
}
