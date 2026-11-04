//
//  ScreenshotMonitorServiceTests.swift
//  DynamicNotchTests
//

import XCTest
import UniformTypeIdentifiers
@testable import DynamicNotch

@MainActor
final class ScreenshotMonitorServiceTests: XCTestCase {
    private var stagingDirectory: URL!
    private var service: ScreenshotMonitorService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        stagingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScreenshotMonitorServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        service = ScreenshotMonitorService(stagingDirectoryURL: stagingDirectory)
    }

    override func tearDown() {
        if let stagingDirectory {
            try? FileManager.default.removeItem(at: stagingDirectory)
        }
        service = nil
        stagingDirectory = nil
        super.tearDown()
    }

    func testStagingDirectoryIsInjectable() {
        XCTAssertEqual(service.rawStagingDirectoryURL(), stagingDirectory)
    }

    func testValidScreenshotIsReportedOnceWithAPreview() throws {
        let url = stagingDirectory.appendingPathComponent("Screenshot 2026-11-02 at 17.00.00.png")
        try ScreenshotTestImages.write(width: 3000, height: 1800, type: UTType.png.identifier, to: url)

        var captures: [(image: NSImage, preview: NSImage, url: URL?, name: String)] = []
        let captured = expectation(description: "onScreenshotCaptured")
        service.onScreenshotCaptured = { image, preview, url, name in
            captures.append((image, preview, url, name))
            captured.fulfill()
        }

        service.scanForNewScreenshots()
        service.scanForNewScreenshots()
        wait(for: [captured], timeout: 5)
        waitUntilNoDecodeIsInFlight()
        service.scanForNewScreenshots()
        waitUntilNoDecodeIsInFlight()

        XCTAssertEqual(captures.count, 1)
        let capture = try XCTUnwrap(captures.first)
        XCTAssertEqual(capture.url?.resolvingSymlinksInPath(), url.resolvingSymlinksInPath())
        XCTAssertEqual(capture.name, url.lastPathComponent)
        XCTAssertEqual(capture.image.cgImage(forProposedRect: nil, context: nil, hints: nil)?.width, 3000)
        let preview = try XCTUnwrap(capture.preview.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertLessThanOrEqual(max(preview.width, preview.height), 1024)
        XCTAssertGreaterThan(preview.width, 0)
    }

    func testTruncatedScreenshotIsReportedOnceAfterItIsComplete() throws {
        let completeURL = stagingDirectory.appendingPathComponent("complete.bin")
        try ScreenshotTestImages.write(width: 3000, height: 1800, type: UTType.png.identifier, to: completeURL)
        let completeData = try Data(contentsOf: completeURL)
        try FileManager.default.removeItem(at: completeURL)

        let url = stagingDirectory.appendingPathComponent("Screenshot 2026-11-02 at 17.00.01.png")
        try Data(completeData.prefix(1000)).write(to: url)

        var captureCount = 0
        service.onScreenshotCaptured = { _, _, _, _ in captureCount += 1 }

        service.scanForNewScreenshots()
        waitUntilNoDecodeIsInFlight()
        XCTAssertEqual(captureCount, 0)

        try completeData.write(to: url)
        let captured = expectation(description: "onScreenshotCaptured after completion")
        service.onScreenshotCaptured = { _, _, _, _ in
            captureCount += 1
            captured.fulfill()
        }
        service.scanForNewScreenshots()
        wait(for: [captured], timeout: 5)
        waitUntilNoDecodeIsInFlight()
        service.scanForNewScreenshots()
        waitUntilNoDecodeIsInFlight()

        XCTAssertEqual(captureCount, 1)
    }

    func testUnreadableFileDoesNotHoldUpTheNextScreenshot() throws {
        let unreadableURL = stagingDirectory.appendingPathComponent("Screenshot 2026-11-02 at 17.00.02.png")
        try Data(repeating: 0x42, count: 1000).write(to: unreadableURL)

        var capturedNames: [String] = []
        service.onScreenshotCaptured = { _, _, _, name in capturedNames.append(name) }

        service.scanForNewScreenshots()
        waitUntilNoDecodeIsInFlight()
        XCTAssertEqual(capturedNames, [])

        let validURL = stagingDirectory.appendingPathComponent("Screenshot 2026-11-02 at 17.00.03.png")
        try ScreenshotTestImages.write(width: 3000, height: 1800, type: UTType.png.identifier, to: validURL)
        let captured = expectation(description: "the valid screenshot is reported on the next scan")
        service.onScreenshotCaptured = { _, _, _, name in
            capturedNames.append(name)
            captured.fulfill()
        }

        service.scanForNewScreenshots()
        wait(for: [captured], timeout: 5)
        waitUntilNoDecodeIsInFlight()

        XCTAssertEqual(capturedNames, [validURL.lastPathComponent])

        service.scanForNewScreenshots()
        waitUntilNoDecodeIsInFlight()
        XCTAssertEqual(capturedNames, [validURL.lastPathComponent], "the unreadable file is retried but never reported")
    }

    private func waitUntilNoDecodeIsInFlight(timeout: TimeInterval = 5) {
        let deadline = Date().addingTimeInterval(timeout)
        while !service.decodingPaths.isEmpty && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertTrue(service.decodingPaths.isEmpty, "decode did not finish in \(timeout) s")
    }
}
