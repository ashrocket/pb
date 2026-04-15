// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "clip-01",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "clip-01",
            targets: ["Clip01App"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Clip01App",
            path: "Sources/clip-01",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
