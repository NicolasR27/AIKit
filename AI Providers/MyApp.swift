import SwiftUI

@main struct MyApp: App {
    @State private var providers = ProviderStore()

    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environment(providers)
        }
    }
}
