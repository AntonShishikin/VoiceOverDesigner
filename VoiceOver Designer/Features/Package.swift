// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Editor",
            targets: ["Editor"]),
        .library(
            name: "TextUI",
            targets: ["TextUI"]),
        .library(
            name: "Settings",
            targets: ["Settings"]),
        
        .library(
            name: "Projects",
            targets: ["Projects"]),

        .library(
            name: "CommonUI",
            targets: ["CommonUI"]),
    ],
    dependencies: [
        .package(
            url: "git@github.com:pointfreeco/swift-snapshot-testing.git",
            branch: "main"
        ),
        .package(name: "Document", path: "./../../Document")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Editor",
            dependencies: [
                "Document",
                "CommonUI",
            ]
        ),
        .target(
            name: "TextUI",
            dependencies: [
                "Document",
                "CommonUI",
            ]
        ),
        .target(
            name: "Projects",
            dependencies: [
                "CommonUI",
                "Document",
            ]
        ),
        .target(
            name: "Settings",
            dependencies: [
                "Document",
            ]
        ),
        .target(
            name: "CommonUI",
            dependencies: []
        ),
        
        .testTarget(
            name: "EditorTests",
            dependencies: ["Editor"]),
        .testTarget(
            name: "SettingsTests",
            dependencies: [
                "Settings",
                "Document",
                .product(name: "SnapshotTesting",
                         package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"]
        ),
        .testTarget(
            name: "ProjectsTests",
            dependencies: [
                "Projects",
                "Document",
            ]
        ),
        .testTarget(
            name: "TextUITests",
            dependencies: [
                "TextUI",
                "Document",
            ]
        ),
    ]
)