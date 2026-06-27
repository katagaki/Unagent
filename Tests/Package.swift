// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UnagentTestServer",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "UnagentTestServer",
            path: "Sources/UnagentTestServer"
        )
    ]
)
