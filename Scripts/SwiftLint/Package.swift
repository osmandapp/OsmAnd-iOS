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
            url: "https://github.com/realm/SwiftLint/releases/download/0.65.0/SwiftLintBinary.artifactbundle.zip",
            checksum: "eb333bd76dfb5f46d21fdf3615fe39bb938956ca0b8e94c241c4b2db6e696b90"
        )
    ]
)
