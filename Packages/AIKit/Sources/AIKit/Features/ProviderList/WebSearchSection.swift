import SwiftUI

/// Lets the user decide whether the app's AI looks things up on the web before answering.
struct WebSearchSection: View {
    @Binding var isOn: Bool

    var body: some View {
        Section {
            Toggle(isOn: $isOn) {
                Label(.searchTheWeb, systemImage: "globe")
            }
        } footer: {
            Text(.webSearchNote)
        }
    }
}
