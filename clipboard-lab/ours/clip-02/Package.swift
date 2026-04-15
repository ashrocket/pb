// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "clip-02",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "clip-02",
            targets: ["Clip02App"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Clip02App",
            path: "Sources/clip-02",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreServices"),
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
