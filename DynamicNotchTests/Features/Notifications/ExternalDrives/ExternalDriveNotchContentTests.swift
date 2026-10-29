import XCTest
@testable import DynamicNotch

final class ExternalDriveNotchContentTests: XCTestCase {

    func testIDUsesRegistryID() {
        let drive = ExternalDriveModel(
            id: "/Volumes/TestDrive",
            name: "Test Drive",
            volumeURL: URL(fileURLWithPath: "/Volumes/TestDrive"),
            totalBytes: 64_000_000_000,
            freeBytes: 32_000_000_000,
            isEjectable: true,
            eventType: .connected,
            icon: nil
        )

        let content = ExternalDriveNotchContent(
            drive: drive,
            onOpen: {},
            onEject: nil
        )

        XCTAssertEqual(content.id, NotchContentRegistry.Notifications.externalDrive.id)
    }

    func testSizeCalculations() {
        let drive = ExternalDriveModel(
            id: "/Volumes/TestDrive",
            name: "Test Drive",
            volumeURL: URL(fileURLWithPath: "/Volumes/TestDrive"),
            totalBytes: 64_000_000_000,
            freeBytes: 32_000_000_000,
            isEjectable: true,
            eventType: .connected,
            icon: nil
        )

        let content = ExternalDriveNotchContent(
            drive: drive,
            onOpen: {},
            onEject: nil
        )

        let size = content.compactSize(baseWidth: 200, baseHeight: 40)
        XCTAssertEqual(size.width, 320)
        XCTAssertEqual(size.height, 100)
    }

    func testDynamicIslandSizeCalculations() {
        let drive = ExternalDriveModel(
            id: "/Volumes/TestDrive",
            name: "Test Drive",
            volumeURL: URL(fileURLWithPath: "/Volumes/TestDrive"),
            totalBytes: 64_000_000_000,
            freeBytes: 32_000_000_000,
            isEjectable: true,
            eventType: .connected,
            icon: nil
        )

        let content = ExternalDriveNotchContent(
            drive: drive,
            onOpen: {},
            onEject: nil
        )

        let size = content.dynamicIslandSize(baseWidth: 200, baseHeight: 40)
        XCTAssertEqual(size.width, 430)
        XCTAssertEqual(size.height, 100)
    }

    func testCornerRadius() {
        let drive = ExternalDriveModel(
            id: "/Volumes/TestDrive",
            name: "Test Drive",
            volumeURL: URL(fileURLWithPath: "/Volumes/TestDrive"),
            totalBytes: 64_000_000_000,
            freeBytes: 32_000_000_000,
            isEjectable: true,
            eventType: .connected,
            icon: nil
        )

        let content = ExternalDriveNotchContent(
            drive: drive,
            onOpen: {},
            onEject: nil
        )

        let radii = content.compactCornerRadius(baseRadius: 10)
        XCTAssertEqual(radii.top, 20)
        XCTAssertEqual(radii.bottom, 38)
    }

    func testFormattedCapacity() {
        let driveWithCapacity = ExternalDriveModel(
            id: "/Volumes/TestDrive",
            name: "Test Drive",
            volumeURL: URL(fileURLWithPath: "/Volumes/TestDrive"),
            totalBytes: 64_000_000_000,
            freeBytes: 32_000_000_000,
            isEjectable: true,
            eventType: .connected,
            icon: nil
        )

        XCTAssertNotNil(driveWithCapacity.formattedCapacity)

        let driveZeroBytes = ExternalDriveModel(
            id: "/Volumes/TestDrive",
            name: "Test Drive",
            volumeURL: nil,
            totalBytes: 0,
            freeBytes: 0,
            isEjectable: true,
            eventType: .ejected,
            icon: nil
        )

        XCTAssertNil(driveZeroBytes.formattedCapacity)
    }

    func testInternalAndVirtualVolumesAreNotExternalPortDevices() {
        let monitor = ExternalDrivesMonitor()

        // Root internal volume must not be recognized as an external port device
        XCTAssertFalse(monitor.isExternalPortConnectedDevice(url: URL(fileURLWithPath: "/")))

        // System directories must not be recognized as external port devices
        XCTAssertFalse(monitor.isExternalPortConnectedDevice(url: URL(fileURLWithPath: "/System")))
        XCTAssertFalse(monitor.isExternalPortConnectedDevice(url: URL(fileURLWithPath: "/private")))

        // Non-file URLs
        if let webURL = URL(string: "https://apple.com") {
            XCTAssertFalse(monitor.isExternalPortConnectedDevice(url: webURL))
        }

        // Non-existent volume paths
        XCTAssertFalse(monitor.isExternalPortConnectedDevice(url: URL(fileURLWithPath: "/Volumes/NonExistentDisk12345")))
    }
}
