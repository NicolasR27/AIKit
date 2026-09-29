import SwiftUI

/// A red warning line for section footers, e.g. a failed connection check.
struct ErrorLabel: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
    }
}
