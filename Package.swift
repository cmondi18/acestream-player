// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AceStreamPlayer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AceStreamPlayer",
            path: "Sources/AceStreamPlayer"
        )
    ]
)
