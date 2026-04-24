import XCTest
@testable import DynamicNotch

final class SettingsSelectionHistoryTests: XCTestCase {
    func testRecordAppendsSelectionToHistory() {
        var history = SettingsRootViewModel.SelectionHistory(initialSelection: .general)

        history.record(.network)

        XCTAssertEqual(history.currentSelection, .network)
        XCTAssertTrue(history.canGoBack)
        XCTAssertFalse(history.canGoForward)
    }

    func testRecordAfterGoingBackDropsForwardHistory() {
        var history = SettingsRootViewModel.SelectionHistory(initialSelection: .general)
        history.record(.network)
        history.record(.battery)

        XCTAssertEqual(history.goBack(), .network)

        history.record(.about)

        XCTAssertEqual(history.currentSelection, .about)
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
        history.record(.network)
        history.record(.battery)

        XCTAssertEqual(history.goBack(), .network)
        XCTAssertEqual(history.goBack(), .general)
        XCTAssertNil(history.goBack())

        XCTAssertEqual(history.goForward(), .network)
        XCTAssertEqual(history.goForward(), .battery)
        XCTAssertNil(history.goForward())
    }
}
