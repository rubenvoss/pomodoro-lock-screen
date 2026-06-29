// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PomodoroLockScreen",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "PomodoroLockScreenCore", targets: ["PomodoroLockScreenCore"]),
        .executable(name: "PomodoroLockScreen", targets: ["PomodoroLockScreen"])
    ],
    targets: [
        .target(
            name: "PomodoroLockScreenCore"
        ),
        .executableTarget(
            name: "PomodoroLockScreen",
            dependencies: ["PomodoroLockScreenCore"],
            path: "Sources/PomodoroLockScreen"
        ),
        .testTarget(
            name: "PomodoroLockScreenCoreTests",
            dependencies: ["PomodoroLockScreenCore"]
        )
    ]
)
