import XCTest
@testable import DynamicNotch

final class NotchTransitionMetricsTests: XCTestCase {
    func testHorizontalCompensationOffsetMatchesCompactReferenceWidth() {
        let offset = NotchTransitionMetrics.horizontalCompensationOffset(for: 260)

        XCTAssertEqual(offset, -60, accuracy: 0.001)
    }

    func testHorizontalCompensationOffsetMatchesExpandedReferenceWidth() {
        let offset = NotchTransitionMetrics.horizontalCompensationOffset(for: 390)

        XCTAssertEqual(offset, -90, accuracy: 0.001)
    }

    func testHorizontalCompensationOffsetGrowsWithNotchWidth() {
        let compactOffset = NotchTransitionMetrics.horizontalCompensationOffset(for: 260)
        let expandedOffset = NotchTransitionMetrics.horizontalCompensationOffset(for: 390)

        XCTAssertLessThan(expandedOffset, compactOffset)
    }

    func testVerticalCompensationOffsetIsZeroForBaseHeight() {
        let offset = NotchTransitionMetrics.verticalCompensationOffset(
            for: 38,
            baseHeight: 38
        )

        XCTAssertEqual(offset, 0, accuracy: 0.001)
    }

    func testVerticalCompensationOffsetUsesHalfOfExtraHeight() {
        let offset = NotchTransitionMetrics.verticalCompensationOffset(
            for: 148,
            baseHeight: 38
        )

        XCTAssertEqual(offset, -55, accuracy: 0.001)
    }
}
