// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-serialization",
    products: [
        .library(
            name: "SwiftSerialization",
            targets: ["SwiftSerialization"]
        )
    ],
    dependencies: [
        // Macros
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "SwiftSerializationMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax")
            ]
        ),

        .target(
            name: "SwiftSerialization",
            dependencies: [
                "SwiftSerializationMacros"
            ]
        ),
        .testTarget(
            name: "SwiftSerializationTests",
            dependencies: ["SwiftSerialization"]
        ),
    ]
)
