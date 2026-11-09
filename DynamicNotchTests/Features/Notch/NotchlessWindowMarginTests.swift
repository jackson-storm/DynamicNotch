import XCTest
@testable import DynamicNotch

final class NotchlessWindowMarginTests: XCTestCase {
    private let builtIn: CGDirectDisplayID = 1
    private let leftExternal: CGDirectDisplayID = 2
    private let rightExternal: CGDirectDisplayID = 3

    func testAppliesOnlyOnTheDisplayThatShowsTheIsland() {
        XCTAssertTrue(NotchlessWindowMargin.applies(toDisplay: leftExternal, islandDisplayID: leftExternal, islandDisplayHasNotch: false))
        XCTAssertFalse(NotchlessWindowMargin.applies(toDisplay: rightExternal, islandDisplayID: leftExternal, islandDisplayHasNotch: false))
    }

    func testDoesNotApplyToOtherDisplaysWhenTheIslandSitsInANotch() {
        // The island on the built-in display sits in the notch; the externals show nothing to keep windows clear of.
        XCTAssertFalse(NotchlessWindowMargin.applies(toDisplay: leftExternal, islandDisplayID: builtIn, islandDisplayHasNotch: true))
        XCTAssertFalse(NotchlessWindowMargin.applies(toDisplay: rightExternal, islandDisplayID: builtIn, islandDisplayHasNotch: true))
        XCTAssertFalse(NotchlessWindowMargin.applies(toDisplay: builtIn, islandDisplayID: builtIn, islandDisplayHasNotch: true))
    }

    func testDoesNotApplyWhenNoDisplayShowsTheIsland() {
        XCTAssertFalse(NotchlessWindowMargin.applies(toDisplay: leftExternal, islandDisplayID: nil, islandDisplayHasNotch: false))
        XCTAssertFalse(NotchlessWindowMargin.applies(toDisplay: nil, islandDisplayID: leftExternal, islandDisplayHasNotch: false))
    }
}
