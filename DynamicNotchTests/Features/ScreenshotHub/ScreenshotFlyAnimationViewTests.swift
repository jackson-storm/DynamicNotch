//
//  ScreenshotFlyAnimationViewTests.swift
//  DynamicNotchTests
//

import XCTest
@testable import DynamicNotch

@MainActor
final class ScreenshotFlyAnimationViewTests: XCTestCase {
    private let screenSize = CGSize(width: 1920, height: 1200)
    private let notch = CGPoint(x: 960, y: -12)
    private let aspect: CGFloat = 1920.0 / 1200.0

    func testBoundsContainStartAndNotchWithMargin() {
        let start = CGPoint(x: 400, y: 700)

        let bounds = ScreenshotFlyAnimationView.flightBounds(
            start: start, notch: notch, screenSize: screenSize, imageAspect: aspect
        )

        // The widest strip is 360 pt and the tallest is 360 / 1.6 pt, so the start point needs
        // at least half the width and the full height of room on each side that is not clamped.
        XCTAssertTrue(bounds.insetBy(dx: 180, dy: 225).contains(start))
        XCTAssertEqual(bounds.minY, 0)
        XCTAssertLessThanOrEqual(bounds.minX, notch.x - 180)
        XCTAssertGreaterThanOrEqual(bounds.maxX, notch.x + 180)
    }

    func testBoundsAreClampedToTheScreen() {
        let screenRect = CGRect(origin: .zero, size: screenSize)
        let starts = [CGPoint(x: 70, y: 1130), CGPoint(x: 1850, y: 1130), CGPoint(x: 960, y: 600), CGPoint(x: 70, y: 90)]

        for start in starts {
            let bounds = ScreenshotFlyAnimationView.flightBounds(
                start: start, notch: notch, screenSize: screenSize, imageAspect: aspect
            )
            XCTAssertTrue(screenRect.contains(bounds), "\(bounds) for start \(start)")
            XCTAssertFalse(bounds.isEmpty)
            XCTAssertEqual(bounds, bounds.integral)
        }
    }

    func testBoundsForBottomRightStartAreSmallerThanTheScreen() {
        let start = CGPoint(x: 1850, y: 1130)

        let bounds = ScreenshotFlyAnimationView.flightBounds(
            start: start, notch: notch, screenSize: screenSize, imageAspect: aspect
        )

        XCTAssertLessThan(bounds.width * bounds.height, screenSize.width * screenSize.height)
        XCTAssertLessThan(bounds.minX, notch.x)
        XCTAssertGreaterThan(bounds.minX, 0)
    }

    func testBoundsForStartAtNotchStillHoldTheImageAndMargins() {
        let point = CGPoint(x: 960, y: 600)

        let bounds = ScreenshotFlyAnimationView.flightBounds(
            start: point, notch: point, screenSize: screenSize, imageAspect: aspect
        )

        let baseWidth: CGFloat = 360
        let baseHeight = baseWidth / aspect
        XCTAssertGreaterThanOrEqual(bounds.width, baseWidth + 2 * 42)
        XCTAssertGreaterThanOrEqual(bounds.height, baseHeight + 2 * 42)
        XCTAssertTrue(bounds.contains(point))
    }
}
