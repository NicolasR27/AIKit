// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AIKit",
    platforms: [.iOS("27.0")],
    products: [
        .library(name: "AIKit", targets: ["AIKit"]),
    ],
    targets: [
        .target(
            name: "AIKit",
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
