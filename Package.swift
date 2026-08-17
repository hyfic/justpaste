// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "JustPaste",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "JustPaste", targets: ["JustPaste"])
    ],
    targets: [
        .executableTarget(name: "JustPaste"),
        .testTarget(
            name: "JustPasteTests",
            dependencies: ["JustPaste"]
        )
    ]
)
