// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AFNetworking",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AFNetworking",
            targets: ["AFNetworking"]
        )
    ],
    targets: [
        .target(
            name: "AFNetworking",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/AFNetworking")
            ],
            linkerSettings: [
                .linkedFramework("MobileCoreServices"),
                .linkedFramework("Security"),
                .linkedFramework("SystemConfiguration")
            ]
        )
    ]
)
