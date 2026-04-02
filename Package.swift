// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OghamNote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "OghamNote", targets: ["OghamNote"])
    ],
    dependencies: [
        .package(url: "https://github.com/kaii-zen/libvim.swift", branch: "master"),
        .package(url: "https://github.com/apple/swift-markdown", branch: "main") // For markdown parsing
    ],
    targets: [
        .executableTarget(
            name: "OghamNote",
            dependencies: [
                .product(name: "libvim", package: "libvim.swift"),
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/OghamNote"
        )
    ]
)
