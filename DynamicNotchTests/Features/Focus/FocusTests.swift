import XCTest
@testable import DynamicNotch

final class FocusTests: XCTestCase {
    func testSleepModeIdentifierResolution() {
        XCTAssertEqual(FocusModeType(identifier: "com.apple.focus.sleep"), .sleep)
        XCTAssertEqual(FocusModeType(identifier: "com.apple.sleep.sleep-mode"), .sleep)
        XCTAssertEqual(FocusModeType(identifier: "com.apple.sleep"), .sleep)
        XCTAssertEqual(FocusModeType(identifier: "com.apple.donotdisturb.mode.sleep"), .sleep)
        XCTAssertEqual(FocusModeType.resolve(identifier: "com.apple.sleep.sleep-mode", name: "Sleep"), .sleep)
        XCTAssertEqual(FocusModeType.resolve(identifier: nil, name: "Sleep"), .sleep)
        XCTAssertEqual(FocusModeType.resolve(identifier: nil, name: "Сон"), .sleep)
        XCTAssertEqual(FocusModeType.resolve(identifier: nil, name: "sleep-mode"), .sleep)
    }

    func testFocusModeTypeDisplayNamesAndIcons() {
        XCTAssertEqual(FocusModeType.sleep.displayName, "Sleep")
        XCTAssertEqual(FocusModeType.sleep.icon, "bed.double.fill")
        XCTAssertEqual(FocusModeType.work.displayName, "Work")
        XCTAssertEqual(FocusModeType.doNotDisturb.displayName, "Do Not Disturb")
    }

    func testFocusLogStreamProcessesStartingOneAsActivation() {
        let stream = FocusLogStream()
        var receivedIdentifier: String?
        let expectation = expectation(description: "Metadata updated")

        stream.onMetadataUpdate = { identifier, _ in
            receivedIdentifier = identifier
            expectation.fulfill()
        }

        stream.processLine("2026-08-24 00:00:00.000 duetexpertd: [com.apple.duetexpertd.atx:mode] semanticModeIdentifier: 'com.apple.focus.sleep'; starting: 1")

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedIdentifier, "com.apple.focus.sleep")
    }

    func testFocusLogStreamProcessesStartingZeroAsDeactivation() {
        let stream = FocusLogStream()
        var lastIdentifier: String?
        var lastName: String?
        let expectation = expectation(description: "Metadata cleared on starting 0")

        // First activate
        stream.processLine("2026-08-24 00:00:00.000 duetexpertd: semanticModeIdentifier: 'com.apple.focus.sleep'; starting: 1")

        stream.onMetadataUpdate = { identifier, name in
            lastIdentifier = identifier
            lastName = name
            expectation.fulfill()
        }

        // Then deactivate via starting: 0
        stream.processLine("2026-08-24 07:00:00.000 duetexpertd: semanticModeIdentifier: 'com.apple.focus.sleep'; starting: 0")

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(lastIdentifier)
        XCTAssertNil(lastName)
    }

    func testFocusLogStreamProcessesNullAssertionAsDeactivation() {
        let stream = FocusLogStream()
        let expectation = expectation(description: "Metadata cleared on null assertion")

        var lastIdentifier: String? = "initial"

        stream.onMetadataUpdate = { identifier, _ in
            lastIdentifier = identifier
            expectation.fulfill()
        }

        stream.processLine("2026-08-24 07:00:00.000 duetexpertd: active mode assertion: (null)")

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(lastIdentifier)
    }

    func testFocusLogStreamProcessesNullSemanticModeIdentifierAsDeactivation() {
        let stream = FocusLogStream()
        let expectation = expectation(description: "Metadata cleared on null semanticModeIdentifier")

        var lastIdentifier: String? = "initial"

        stream.onMetadataUpdate = { identifier, _ in
            lastIdentifier = identifier
            expectation.fulfill()
        }

        stream.processLine("2026-08-24 07:00:00.000 duetexpertd: semanticModeIdentifier: (null)")

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(lastIdentifier)
    }
}
