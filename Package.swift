// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "MergeL10n",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "MergeL10n", targets: ["MergeL10n"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/teufelaudio/FoundationExtensions", from: "0.1.1"),
        .package(url: "https://github.com/teufelaudio/FunctionalParser", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "MergeL10n",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "L10nModels"
            ]
        ),
        .target(
            name: "L10nModels",
            dependencies: [
                .product(name: "FoundationExtensions", package: "FoundationExtensions"),
                "FunctionalParser"
            ]
        ),
        .testTarget(
            name: "MergeL10nTests",
            dependencies: ["L10nModels"]
        )
    ]
)
