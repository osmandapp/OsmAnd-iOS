// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BRCybertron",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "BRCybertron",
            targets: ["BRCybertron"]
        )
    ],
    targets: [
        .target(
            name: "BRCybertron",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/BRCybertron"),
                .headerSearchPath("libxslt"),
                .headerSearchPath("libxslt/libxslt"),
                .headerSearchPath("libxslt/libexslt"),
                .unsafeFlags(["-iwithsysroot", "/usr/include/libxml2"])
            ],
            linkerSettings: [
                .linkedLibrary("xml2")
            ]
        )
    ]
)
