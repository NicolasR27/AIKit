import SwiftUI

/// Footnote at the bottom of the list about where keys are stored.
struct PrivacyNoteSection: View {
    let note: LocalizedStringResource

    var body: some View {
        Section {
            Label {
                Text(note)
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
