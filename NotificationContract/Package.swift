// swift-tools-version: 6.0
import PackageDescription

// Pure-Foundation wire contract shared by the app and the `dynamicnotch` CLI: the
// notification payload, the core severity level, inbox-path derivation and the atomic
// drop mechanism. Zero dependencies — no SwiftUI/AppKit — so both the GUI app and a
// command-line binary can link it without dragging in a UI stack.
let package = Package(
    name: "NotificationContract",
    products: [
        .library(name: "NotificationContract", targets: ["NotificationContract"]),
    ],
    targets: [
        .target(name: "NotificationContract"),
        .testTarget(
            name: "NotificationContractTests",
            dependencies: ["NotificationContract"]
        ),
    ]
)
