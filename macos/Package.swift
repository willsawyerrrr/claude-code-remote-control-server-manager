// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RemoteControlManager",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "RemoteControlManager",
            path: "Sources/RemoteControlManager"
        )
    ]
)
