// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CycleCare",
    defaultLocalization: "vi",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CycleCare",
            targets: ["CycleCare"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CycleCare",
            dependencies: [],
            path: "CycleCare",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CycleCareTests",
            dependencies: ["CycleCare"],
            path: "CycleCareTests"
        )
    ]
)
