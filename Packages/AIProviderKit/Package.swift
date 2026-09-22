// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AIProviderKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "AIProviderKit", targets: ["AIProviderKit"]),
    ],
    targets: [
        .target(
            name: "AIProviderKit",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
    ]
)
