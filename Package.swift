// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TextHighlighter",
    platforms: [
        .macOS(.v11) // Requiere AppKit
    ],
    products: [
        .library(
            name: "TextHighlighter",
            targets: ["TextHighlighter"]
        )
    ],
    targets: [
        .target(
            name: "TextHighlighter",
            path: "Sources/TextHighlighter",
            sources: ["Core", "UI"],
            publicHeadersPath: nil
        ),
        .testTarget(
            name: "TextHighlighterTests",
            dependencies: ["TextHighlighter"]
        )
    ]
)
