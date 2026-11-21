import XCTest
@testable import DynamicNotch

final class ManagedDisplaySpacesTests: XCTestCase {
    private let displayUUID = "37D8832A-2D66-02CA-B9F7-8F30A301B230"

    func testFullscreenSpaceOnMatchingDisplayIsDetected() {
        let spaces = [displayEntry(identifier: displayUUID, currentSpaceType: 4)]

        XCTAssertTrue(ManagedDisplaySpaces.isFullscreenSpaceActive(in: spaces, displayIdentifier: displayUUID))
    }

    func testDesktopSpaceOnMatchingDisplayIsNotFullscreen() {
        let spaces = [displayEntry(identifier: displayUUID, currentSpaceType: 0)]

        XCTAssertFalse(ManagedDisplaySpaces.isFullscreenSpaceActive(in: spaces, displayIdentifier: displayUUID))
    }

    func testDisplayIdentifierMatchIgnoresCase() {
        let spaces = [displayEntry(identifier: displayUUID.lowercased(), currentSpaceType: 4)]

        XCTAssertTrue(ManagedDisplaySpaces.isFullscreenSpaceActive(in: spaces, displayIdentifier: displayUUID))
    }

    func testFullscreenSpaceIsDetectedWhenDisplaysShareSpaces() {
        // With "Displays have separate Spaces" turned off, WindowServer reports one "Main" entry.
        let spaces = [displayEntry(identifier: "Main", currentSpaceType: 4)]

        XCTAssertTrue(ManagedDisplaySpaces.isFullscreenSpaceActive(in: spaces, displayIdentifier: displayUUID))
    }

    func testDesktopSpaceIsNotFullscreenWhenDisplaysShareSpaces() {
        let spaces = [displayEntry(identifier: "Main", currentSpaceType: 0)]

        XCTAssertFalse(ManagedDisplaySpaces.isFullscreenSpaceActive(in: spaces, displayIdentifier: displayUUID))
    }

    func testOtherDisplaysFullscreenSpaceIsIgnored() {
        let spaces = [
            displayEntry(identifier: "EXTERNAL-DISPLAY-UUID", currentSpaceType: 4),
            displayEntry(identifier: displayUUID, currentSpaceType: 0)
        ]

        XCTAssertFalse(ManagedDisplaySpaces.isFullscreenSpaceActive(in: spaces, displayIdentifier: displayUUID))
    }

    func testMissingDisplayEntryIsNotFullscreen() {
        let spaces = [displayEntry(identifier: "EXTERNAL-DISPLAY-UUID", currentSpaceType: 4)]

        XCTAssertFalse(ManagedDisplaySpaces.isFullscreenSpaceActive(in: spaces, displayIdentifier: displayUUID))
    }

    private func displayEntry(identifier: String, currentSpaceType: Int) -> [String: Any] {
        [
            "Display Identifier": identifier,
            "Current Space": ["type": NSNumber(value: currentSpaceType)]
        ]
    }
}
