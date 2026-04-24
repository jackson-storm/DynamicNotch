import XCTest
@testable import DynamicNotch

final class DynamicIslandTransitionMetricsTests: XCTestCase {
    func testHorizontalCompensationOffsetMatchesCompactReferenceWidth() {
        let offset = DynamicIslandTransitionMetrics.horizontalCompensationOffset(for: 260)

        XCTAssertEqual(offset, -60, accuracy: 0.001)
    }

    func testHorizontalCompensationOffsetMatchesExpandedReferenceWidth() {
        let offset = DynamicIslandTransitionMetrics.horizontalCompensationOffset(for: 390)

        XCTAssertEqual(offset, -90, accuracy: 0.001)
    }

    func testHorizontalCompensationOffsetGrowsWithNotchWidth() {
        let compactOffset = DynamicIslandTransitionMetrics.horizontalCompensationOffset(for: 260)
        let expandedOffset = DynamicIslandTransitionMetrics.horizontalCompensationOffset(for: 390)

        XCTAssertLessThan(expandedOffset, compactOffset)
    }

    func testVerticalCompensationOffsetIsZeroForBaseHeight() {
        let offset = DynamicIslandTransitionMetrics.verticalCompensationOffset(
            for: 38,
            baseHeight: 38
        )

        XCTAssertEqual(offset, 0, accuracy: 0.001)
    }

    func testVerticalCompensationOffsetUsesHalfOfExtraHeight() {
        let offset = DynamicIslandTransitionMetrics.verticalCompensationOffset(
            for: 148,
            baseHeight: 38
        )

        XCTAssertEqual(offset, -55, accuracy: 0.001)
    }
}
