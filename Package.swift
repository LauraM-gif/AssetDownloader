<<<<<<< HEAD
// swift-tools-version:5.2
=======
// swift-tools-version:5.3
>>>>>>> a2d5d38... Initial commit including only avasset abstractions
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let projectName = "AssetDownloader"

let package = Package(
    name: "AssetDownloader",
    platforms: [
<<<<<<< HEAD
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15)
=======
        .iOS(.v13)
>>>>>>> a2d5d38... Initial commit including only avasset abstractions
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
