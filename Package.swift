// swift-tools-version: 6.2
// Lets other apps add AIKit straight from this repo's URL.
import PackageDescription

let package = Package(
    name: "AIKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "AIKit", targets: ["AIKit"]),
    ],
    targets: [
        .target(
            name: "AIKit",
            path: "Packages/AIKit/Sources/AIKit",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
    ]
)
