import SwiftUI

struct DefaultProviderSection: View {
    @Binding var isDefault: Bool

    var body: some View {
        Section {
            Toggle(.useAsDefault, isOn: $isDefault)
        }
    }
}
