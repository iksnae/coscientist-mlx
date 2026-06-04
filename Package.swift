// swift-tools-version: 6.0
import PackageDescription

// Architecture (see docs/ARCHITECTURE.md):
//   AICoScientistKit  — pure domain + protocol boundaries. NO MLX import. Fast unit tests.
//   AICoScientistMLX  — the MLX adapter (M1+). All `import MLX*` is quarantined here.
//   AICoScientistCLI  — driver, depends on both.
// This keeps the core testable and swappable (DIP) and isolates MLX's churn/build cost.
let package = Package(
    name: "coscientist-mlx",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AICoScientistKit", targets: ["AICoScientistKit"]),
        .library(name: "AICoScientistMLX", targets: ["AICoScientistMLX"]),
        .executable(name: "aicoscientist", targets: ["AICoScientistCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.31.4"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", .upToNextMajor(from: "3.31.3")),
        // Required by the MLXHuggingFace loader macro: its expansion references the
        // `HuggingFace` and `Tokenizers` modules, which the consumer must supply.
        .package(url: "https://github.com/huggingface/swift-huggingface", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/huggingface/swift-transformers", .upToNextMajor(from: "1.3.0")),
    ],
    targets: [
        .target(
            name: "AICoScientistKit",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "AICoScientistMLX",
            dependencies: [
                "AICoScientistKit",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ]
        ),
        .executableTarget(
            name: "AICoScientistCLI",
            dependencies: [
                "AICoScientistKit",
                "AICoScientistMLX",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "AICoScientistKitTests",
            dependencies: ["AICoScientistKit"]
        ),
        .testTarget(
            name: "AICoScientistMLXTests",
            dependencies: ["AICoScientistMLX"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
