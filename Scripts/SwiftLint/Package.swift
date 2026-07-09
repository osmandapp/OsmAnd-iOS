// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftLint",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.63.0/SwiftLintBinary.artifactbundle.zip",
            checksum: "b51ca39ffe2331fe0337f9267d4b0dea2c182791a2fd0f3b961d7cbfb6d488d7"
        )
    ]
)
