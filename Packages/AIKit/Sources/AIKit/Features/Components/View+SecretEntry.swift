import SwiftUI

extension View {
    /// Keys and URLs shouldn't be autocorrected or capitalized.
    func secretEntry() -> some View {
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }
}
