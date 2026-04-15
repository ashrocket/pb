// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "clip-05",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "clip-05",
            targets: ["Clip05App"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Clip05App",
            path: "Sources/clip-05",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreServices"),
                .linkedFramework("CoreText"),
                .linkedFramework("CryptoKit"),
                .linkedFramework("ImageIO"),
                .linkedFramework("Security"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("Vision"),
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "Clip05HarnessTests",
            dependencies: ["Clip05App"],
            path: "Tests/QueryParserTests"
        )
    ]
)
