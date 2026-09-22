import AIProviderKit
import SwiftUI

@main struct MyApp: App {
    @State private var providers = AIProviderStore()

    var body: some Scene {
        WindowGroup {
            AIProviderSettingsView(store: providers)
        }
    }
}
