import SwiftUI

/// Model, default and disconnect, shown once the provider is connected.
/// Apple Intelligence has one model and is switched off with its toggle, so it only gets the default switch.
struct ConnectedSections<ModelPicker: View>: View {
    let provider: AIProvider
    let selectedModel: String?
    @Binding var isDefault: Bool
    let disconnect: () -> Void
    @ViewBuilder let modelPicker: ModelPicker

    var body: some View {
        if !provider.isOnDevice {
            ModelSection(selectedModel: selectedModel) {
                modelPicker
            }
        }
        DefaultProviderSection(isDefault: $isDefault)
        if !provider.isOnDevice {
            DisconnectSection(provider: provider, disconnect: disconnect)
        }
    }
}
