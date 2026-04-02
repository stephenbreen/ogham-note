// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OghamNote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "OghamNote", targets: ["OghamNote"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "OghamNote",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/OghamNote",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "OghamNoteTests",
            dependencies: ["OghamNote"]
        )
    ]
)
