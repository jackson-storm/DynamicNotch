import XCTest
@testable import DynamicNotch

final class SettingsSelectionHistoryTests: XCTestCase {
    func testRecordAppendsSelectionToHistory() {
        var history = SettingsRootViewModel.SelectionHistory(initialSelection: .general)

        history.record(.wifi)

        XCTAssertEqual(history.currentSelection, .wifi)
        XCTAssertTrue(history.canGoBack)
        XCTAssertFalse(history.canGoForward)
    }

    func testRecordAfterGoingBackDropsForwardHistory() {
        var history = SettingsRootViewModel.SelectionHistory(initialSelection: .general)
        history.record(.wifi)
        history.record(.battery)

        XCTAssertEqual(history.goBack(), .wifi)

        history.record(.notch)

        XCTAssertEqual(history.currentSelection, .notch)
        XCTAssertNil(history.goForward())
    }

    func testRecordSameSelectionDoesNotDuplicateHistory() {
        var history = SettingsRootViewModel.SelectionHistory(initialSelection: .general)

        history.record(.general)

        XCTAssertFalse(history.canGoBack)
        XCTAssertFalse(history.canGoForward)
        XCTAssertNil(history.goBack())
    }

    func testBackAndForwardMoveAcrossRecordedSelections() {
        var history = SettingsRootViewModel.SelectionHistory(initialSelection: .general)
        history.record(.wifi)
        history.record(.battery)

        XCTAssertEqual(history.goBack(), .wifi)
        XCTAssertEqual(history.goBack(), .general)
        XCTAssertNil(history.goBack())

        XCTAssertEqual(history.goForward(), .wifi)
        XCTAssertEqual(history.goForward(), .battery)
        XCTAssertNil(history.goForward())
    }
}
