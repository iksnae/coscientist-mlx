// swift-tools-version: 6.0
import PackageDescription

// MLX dependencies (mlx-swift, mlx-swift-lm) are introduced in milestone M1, once the
// inference adapter lands. M0 is a buildable, fully-tested pure-Swift skeleton with a mock
// language model so the domain types, Elo math, JSON handling, and the protocol boundaries
// can be developed test-first without a GPU or model download. See docs/ARCHITECTURE.md.
let package = Package(
    name: "coscientist-mlx",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AICoScientistKit", targets: ["AICoScientistKit"]),
        .executable(name: "aicoscientist", targets: ["AICoScientistCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
    ],
    targets: [
        .target(
            name: "AICoScientistKit",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .executableTarget(
            name: "AICoScientistCLI",
            dependencies: [
                "AICoScientistKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "AICoScientistKitTests",
            dependencies: ["AICoScientistKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
