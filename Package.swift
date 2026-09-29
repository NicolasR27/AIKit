// swift-tools-version: 6.2
// Lets other apps add AIKit straight from this repo's URL.
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
            path: "Packages/AIKit/Sources/AIKit",
            resources: [.process("Resources")],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
        .testTarget(
            name: "AIKitTests",
            dependencies: ["AIKit"],
            path: "Packages/AIKit/Tests/AIKitTests",
        ),
    ]
)
