// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "clip-03",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "clip-03",
            targets: ["Clip03App"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Clip03App",
            path: "Sources/clip-03",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreServices"),
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "QueryParserTests",
            dependencies: ["Clip03App"],
            path: "Tests/QueryParserTests"
        )
    ]
)
