import XCTest
@testable import DynamicNotch

final class NotchTransitionMetricsTests: XCTestCase {
    func testVerticalCompensationOffsetIsZeroForBaseHeight() {
        let offset = NotchTransitionMetrics.verticalCompensationOffset(
            for: 38,
            baseHeight: 38
        )

        XCTAssertEqual(offset, 0, accuracy: 0.001)
    }

    func testVerticalCompensationOffsetMatchesExtraHeightMinusThirtyPercent() {
        // baseHeight + 140 -> -98 (140 * 0.7)
        let offset = NotchTransitionMetrics.verticalCompensationOffset(
            for: 178,
            baseHeight: 38
        )

        XCTAssertEqual(offset, -98, accuracy: 0.001)
    }

    func testCompactScaleXReturnsDefaultWhenExtraWidthIsLessThanOrEqualTo70() {
        // baseWidth + 70
        XCTAssertEqual(
            NotchTransitionMetrics.compactScaleX(for: 270, baseWidth: 200),
            0.8,
            accuracy: 0.001
        )
        // baseWidth + 30
        XCTAssertEqual(
            NotchTransitionMetrics.compactScaleX(for: 230, baseWidth: 200),
            0.8,
            accuracy: 0.001
        )
        // baseWidth (extra width 0)
        XCTAssertEqual(
            NotchTransitionMetrics.compactScaleX(for: 200, baseWidth: 200),
            0.8,
            accuracy: 0.001
        )
    }

    func testCompactScaleXForExtraWidth140Is0_5() {
        // baseWidth + 140 -> 0.5
        let scale = NotchTransitionMetrics.compactScaleX(for: 340, baseWidth: 200)
        XCTAssertEqual(scale, 0.5, accuracy: 0.001)
    }

    func testCompactScaleXClampsToMinimumBound() {
        let scale = NotchTransitionMetrics.compactScaleX(for: 1000, baseWidth: 200)
        XCTAssertEqual(scale, 0.2, accuracy: 0.001)
    }

    func testCompactScaleYReturns1_0ForBaseHeightOrLess() {
        XCTAssertEqual(
            NotchTransitionMetrics.compactScaleY(for: 38, baseHeight: 38),
            1.0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            NotchTransitionMetrics.compactScaleY(for: 30, baseHeight: 38),
            1.0,
            accuracy: 0.001
        )
    }

    func testCompactScaleYForExtraHeight70Is0_7() {
        // baseHeight + 70 -> 0.7
        let scale = NotchTransitionMetrics.compactScaleY(for: 108, baseHeight: 38)
        XCTAssertEqual(scale, 0.7, accuracy: 0.001)
    }

    func testCompactScaleYForExtraHeight140Is0_4() {
        // baseHeight + 140 -> 0.4
        let scale = NotchTransitionMetrics.compactScaleY(for: 178, baseHeight: 38)
        XCTAssertEqual(scale, 0.4, accuracy: 0.001)
    }

    func testCompactScaleYClampsToMinimumBoundForExtraHeightGreaterThan140() {
        let scale = NotchTransitionMetrics.compactScaleY(for: 300, baseHeight: 38)
        XCTAssertEqual(scale, 0.4, accuracy: 0.001)
    }
}
