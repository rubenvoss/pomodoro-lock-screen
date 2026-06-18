// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PomodoroLockScreen",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PomodoroLockScreen", targets: ["PomodoroLockScreen"])
    ],
    targets: [
        .executableTarget(
            name: "PomodoroLockScreen",
            path: "Sources/PomodoroLockScreen"
        )
    ]
)
