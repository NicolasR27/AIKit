// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AIKit",
    defaultLocalization: "en",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "AIKit", targets: ["AIKit"]),
    ],
    targets: [
        .target(
            name: "AIKit",
            resources: [.process("Resources")],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
        .testTarget(
            name: "AIKitTests",
            dependencies: ["AIKit"],
        ),
    ]
)
