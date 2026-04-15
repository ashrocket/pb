// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "clip-04",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "clip-04",
            targets: ["Clip04App"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Clip04App",
            path: "Sources/clip-04",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreServices"),
                .linkedFramework("CryptoKit"),
                .linkedFramework("Security"),
                .linkedFramework("ServiceManagement"),
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "Clip04HarnessTests",
            dependencies: ["Clip04App"],
            path: "Tests/QueryParserTests"
        )
    ]
)
