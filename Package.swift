// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLexicalLookup-Example",
    platforms: [
            .macOS(.v10_15)
        ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-syntax.git", branch: "main")
    ], targets: [
      .executableTarget(
        name: "SwiftLexicalLookup-Example", dependencies: [
          .product(name: "SwiftSyntax", package: "swift-syntax"),
          .product(name: "SwiftParser", package: "swift-syntax"),
          .product(name: "SwiftLexicalLookup", package: "swift-syntax"),
        ]),
    ]
)
