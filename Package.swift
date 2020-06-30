// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MergeL10n",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "MergeL10n", targets: ["MergeL10n"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "0.0.6")),
        .package(url: "https://github.com/teufelaudio/FoundationExtensions", .upToNextMajor(from: "0.1.1")),
        .package(url: "https://github.com/teufelaudio/FunctionalParser", .branch("master"))
    ],
    targets: [
        .target(
            name: "MergeL10n",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "FoundationExtensionsStatic", package: "FoundationExtensions"),
                "FunctionalParser"
            ]
        )
    ]
)
