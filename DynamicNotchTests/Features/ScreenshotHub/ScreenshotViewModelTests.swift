//
//  ScreenshotViewModelTests.swift
//  DynamicNotchTests
//

import XCTest
import Combine
@testable import DynamicNotch

@MainActor
final class ScreenshotViewModelTests: XCTestCase {
    private var viewModel: ScreenshotViewModel!
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScreenshotViewModelTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        viewModel = ScreenshotViewModel()
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        viewModel = nil
        tempDirectory = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertNil(viewModel.activeScreenshot)
        XCTAssertFalse(viewModel.isDropped)
        XCTAssertFalse(viewModel.isDeleted)
        XCTAssertFalse(viewModel.isSavedToDisk)
        XCTAssertFalse(viewModel.isCopied)
    }

    func testProcessNewScreenshotSetsActiveScreenshotAndNotifiesListener() {
        let expectation = expectation(description: "onScreenshotReady called")
        var receivedScreenshot: ScreenshotModel?

        viewModel.onScreenshotReady = { screenshot in
            receivedScreenshot = screenshot
            expectation.fulfill()
        }

        let dummyImage = NSImage(size: NSSize(width: 100, height: 100))
        let sampleFile = tempDirectory.appendingPathComponent("test-screenshot.png")
        try? "dummy".write(to: sampleFile, atomically: true, encoding: .utf8)

        viewModel.processNewScreenshot(image: dummyImage, fileURL: sampleFile, fileName: "test-screenshot.png")

        wait(for: [expectation], timeout: 2.0)

        XCTAssertNotNil(viewModel.activeScreenshot)
        XCTAssertEqual(receivedScreenshot?.fileName, "test-screenshot.png")
        XCTAssertFalse(viewModel.isDropped)
        XCTAssertFalse(viewModel.isDeleted)
    }

    func testDismissInvokesCallback() {
        let expectation = expectation(description: "onScreenshotDismissed called")

        viewModel.onScreenshotDismissed = {
            expectation.fulfill()
        }

        viewModel.dismiss()

        wait(for: [expectation], timeout: 1.0)
    }

    func testMarkAsDropped() {
        XCTAssertFalse(viewModel.isDropped)
        viewModel.markAsDropped()
        XCTAssertTrue(viewModel.isDropped)
    }

    func testDeleteScreenshotSetsFlagAndInvokesDismiss() {
        let expectation = expectation(description: "onScreenshotDismissed called on delete")

        viewModel.onScreenshotDismissed = {
            expectation.fulfill()
        }

        viewModel.deleteScreenshot()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isDeleted)
    }
}
