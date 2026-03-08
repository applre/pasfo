// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "pasfo",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "pasfo",
            path: "Sources/pasfo",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "pasfoTests",
            dependencies: ["pasfo"],
            path: "Tests/pasfoTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
