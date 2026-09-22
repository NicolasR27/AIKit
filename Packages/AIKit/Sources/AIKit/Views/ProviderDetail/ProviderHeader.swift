import SwiftUI

struct ProviderHeader: View {
    let provider: AIProvider

    var body: some View {
        Section {
            VStack {
                ProviderIcon(provider: provider, size: 60)
                Text(provider.displayName)
                    .font(.title2)
                    .bold()
                Text(provider.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
    }
}
