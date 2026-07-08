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

    func testVerticalCompensationOffsetUsesHalfOfExtraHeight() {
        let offset = NotchTransitionMetrics.verticalCompensationOffset(
            for: 148,
            baseHeight: 38
        )

        XCTAssertEqual(offset, -55, accuracy: 0.001)
    }
}
