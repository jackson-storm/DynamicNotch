import XCTest
@testable import DynamicNotch

final class NotchScreenSelectionTests: XCTestCase {
    func testMainPrefersPrimaryDisplayIdentifier() {
        let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: NotchScreenSelectionPreferences(
                displayLocation: .main,
                preferredDisplayUUID: nil,
                allowsAutomaticDisplaySwitching: false
            ),
            candidates: [
                NotchScreenSelectionCandidate(displayID: 11, displayUUID: "BUILTIN", isBuiltIn: true),
                NotchScreenSelectionCandidate(displayID: 42, displayUUID: "EXTERNAL", isBuiltIn: false)
            ],
            primaryDisplayID: 42
        )

        XCTAssertEqual(selectedDisplayID, 42)
    }

    func testMainFallsBackToFirstDisplayWhenPrimaryIdentifierIsMissing() {
        let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: NotchScreenSelectionPreferences(
                displayLocation: .main,
                preferredDisplayUUID: nil,
                allowsAutomaticDisplaySwitching: false
            ),
            candidates: [
                NotchScreenSelectionCandidate(displayID: 11, displayUUID: "BUILTIN", isBuiltIn: true),
                NotchScreenSelectionCandidate(displayID: 42, displayUUID: "EXTERNAL", isBuiltIn: false)
            ],
            primaryDisplayID: 99
        )

        XCTAssertEqual(selectedDisplayID, 11)
    }

    func testBuiltInPrefersBuiltInDisplayIdentifier() {
        let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: NotchScreenSelectionPreferences(
                displayLocation: .builtIn,
                preferredDisplayUUID: nil,
                allowsAutomaticDisplaySwitching: false
            ),
            candidates: [
                NotchScreenSelectionCandidate(displayID: 42, displayUUID: "EXTERNAL", isBuiltIn: false),
                NotchScreenSelectionCandidate(displayID: 11, displayUUID: "BUILTIN", isBuiltIn: true)
            ],
            primaryDisplayID: 42
        )

        XCTAssertEqual(selectedDisplayID, 11)
    }

    func testBuiltInReturnsNilWhenBuiltInDisplayIsUnavailable() {
        let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: NotchScreenSelectionPreferences(
                displayLocation: .builtIn,
                preferredDisplayUUID: nil,
                allowsAutomaticDisplaySwitching: false
            ),
            candidates: [
                NotchScreenSelectionCandidate(displayID: 42, displayUUID: "EXTERNAL", isBuiltIn: false)
            ],
            primaryDisplayID: 42
        )

        XCTAssertNil(selectedDisplayID)
    }

    func testSpecificDisplayPrefersStoredDisplayIdentifier() {
        let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: NotchScreenSelectionPreferences(
                displayLocation: .specific,
                preferredDisplayUUID: "EXTERNAL",
                allowsAutomaticDisplaySwitching: false
            ),
            candidates: [
                NotchScreenSelectionCandidate(displayID: 11, displayUUID: "BUILTIN", isBuiltIn: true),
                NotchScreenSelectionCandidate(displayID: 42, displayUUID: "EXTERNAL", isBuiltIn: false)
            ],
            primaryDisplayID: 11
        )

        XCTAssertEqual(selectedDisplayID, 42)
    }

    func testSpecificDisplayReturnsNilWhenStoredDisplayIsUnavailableAndAutoSwitchDisabled() {
        let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: NotchScreenSelectionPreferences(
                displayLocation: .specific,
                preferredDisplayUUID: "MISSING",
                allowsAutomaticDisplaySwitching: false
            ),
            candidates: [
                NotchScreenSelectionCandidate(displayID: 11, displayUUID: "BUILTIN", isBuiltIn: true)
            ],
            primaryDisplayID: 11
        )

        XCTAssertNil(selectedDisplayID)
    }

    func testSpecificDisplayFallsBackToPrimaryDisplayWhenStoredDisplayIsUnavailableAndAutoSwitchEnabled() {
        let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: NotchScreenSelectionPreferences(
                displayLocation: .specific,
                preferredDisplayUUID: "MISSING",
                allowsAutomaticDisplaySwitching: true
            ),
            candidates: [
                NotchScreenSelectionCandidate(displayID: 11, displayUUID: "BUILTIN", isBuiltIn: true),
                NotchScreenSelectionCandidate(displayID: 42, displayUUID: "EXTERNAL", isBuiltIn: false)
            ],
            primaryDisplayID: 42
        )

        XCTAssertEqual(selectedDisplayID, 42)
    }
}
