// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ComicInfoComicVine",
  platforms: [
    .macOS(.v27),
    .iOS(.v27),
  ],
  products: [
    .library(
      name: "ComicInfoComicVine",
      targets: ["ComicInfoComicVine"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/veganstraightedge/ComicInfo.swift.git", from: "1.10.0"),
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.14.4"),
  ],
  targets: [
    .target(
      name: "ComicInfoComicVine",
      dependencies: [
        .product(name: "ComicInfo", package: "ComicInfo.swift"),
        .product(name: "SwiftSoup", package: "SwiftSoup"),
      ]
    ),
    .testTarget(
      name: "ComicInfoComicVineTests",
      dependencies: ["ComicInfoComicVine"],
      resources: [.copy("Fixtures")]
    ),
  ]
)
