// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let projectName = "AssetDownloader"

let package = Package(
    name: "AssetDownloader",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AssetDownloader",
            type: .dynamic,
            targets: ["AssetDownloader"]),
    ],
    targets: [
        .target(
            name: "AssetDownloader",
            dependencies: []),
        .testTarget(
            name: "AssetDownloaderTests",
            dependencies: ["AssetDownloader"]),
    ]
)
