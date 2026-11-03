// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Scerene",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .macCatalyst(.v13)],
    dependencies: [
        .package(path: "swift-cross-ui"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "Scerene",
            dependencies: [
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "AppKitBackend", package: "swift-cross-ui"),
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
    ]
)
