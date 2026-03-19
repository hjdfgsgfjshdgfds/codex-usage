// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ChatGPTPlusUsageMenubar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ChatGPTPlusUsageMenubar", targets: ["ChatGPTPlusUsageMenubar"])
    ],
    targets: [
        .executableTarget(
            name: "ChatGPTPlusUsageMenubar",
            path: "Sources"
        )
    ]
)
