import XCTest
import AppKit
@testable import DynamicNotch

final class ScreenshotViewModelTests: XCTestCase {
    @MainActor
    func testCancelledDragKeepsScreenshotAvailable() throws {
        let fixture = try makeScreenshotFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directory) }

        let viewModel = ScreenshotViewModel()
        TestLifetime.retain(viewModel)
        viewModel.activeScreenshot = fixture.model
        var dragStates: [Bool] = []
        viewModel.onScreenshotDragStateChanged = { dragStates.append($0) }

        let writer = try XCTUnwrap(
            viewModel.beginDragging(screenshot: fixture.model)
        )
        let types = writer.writableTypes(for: .general)
        let draggedFileURL = try XCTUnwrap(fileURL(from: writer))

        XCTAssertTrue(types.contains(.fileURL))
        XCTAssertTrue(types.contains(.png))
        XCTAssertTrue(types.contains(.tiff))
        XCTAssertTrue(FileManager.default.fileExists(atPath: draggedFileURL.path))
        XCTAssertTrue(viewModel.isDragging)

        viewModel.finishDragging(
            screenshotID: fixture.model.id,
            didDrop: false
        )

        XCTAssertEqual(viewModel.activeScreenshot?.id, fixture.model.id)
        XCTAssertFalse(viewModel.isDropped)
        XCTAssertFalse(viewModel.isDragging)
        XCTAssertEqual(dragStates, [true, false])
        try? FileManager.default.removeItem(at: draggedFileURL)
    }

    @MainActor
    func testSuccessfulDragDismissesWithoutSavingDuplicate() throws {
        let fixture = try makeScreenshotFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directory) }

        let viewModel = ScreenshotViewModel()
        TestLifetime.retain(viewModel)
        viewModel.activeScreenshot = fixture.model
        var didDismiss = false
        viewModel.onScreenshotDismissed = { didDismiss = true }

        XCTAssertNotNil(viewModel.beginDragging(screenshot: fixture.model))
        viewModel.finishDragging(
            screenshotID: fixture.model.id,
            didDrop: true
        )

        XCTAssertTrue(viewModel.isDropped)
        XCTAssertTrue(didDismiss)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: fixture.targetURL.path),
            "A successful copy drag should not also save a duplicate screenshot"
        )
    }

    @MainActor
    func testCancelledDragCompletesDeferredAutoSave() throws {
        let fixture = try makeScreenshotFixture()
        defer { try? FileManager.default.removeItem(at: fixture.directory) }

        let viewModel = ScreenshotViewModel()
        TestLifetime.retain(viewModel)
        viewModel.activeScreenshot = fixture.model

        XCTAssertNotNil(viewModel.beginDragging(screenshot: fixture.model))
        viewModel.saveToDiskIfNeeded()

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: fixture.targetURL.path),
            "Auto-save must not move the source file during an active drag"
        )

        viewModel.finishDragging(
            screenshotID: fixture.model.id,
            didDrop: false
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.targetURL.path))
        XCTAssertTrue(viewModel.isSavedToDisk)
    }

    @MainActor
    private func makeScreenshotFixture() throws -> (
        model: ScreenshotModel,
        directory: URL,
        targetURL: URL
    ) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("DynamicNotchScreenshotTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let image = try makeTestImage()
        let sourceURL = directory.appendingPathComponent("Screenshot source.png")
        let targetURL = directory.appendingPathComponent("Screenshot saved.png")
        let pngData = try XCTUnwrap(
            NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation))?
                .representation(using: .png, properties: [:])
        )
        try pngData.write(to: sourceURL)

        return (
            ScreenshotModel(
                image: image,
                fileURL: sourceURL,
                tempFileURL: sourceURL,
                targetDestinationURL: targetURL,
                fileName: sourceURL.lastPathComponent,
                recognizedText: "",
                isRecognizing: false,
                timestamp: Date()
            ),
            directory,
            targetURL
        )
    }

    @MainActor
    private func makeTestImage() throws -> NSImage {
        let bitmap = try XCTUnwrap(
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: 8,
                pixelsHigh: 6,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        )

        for x in 0..<8 {
            for y in 0..<6 {
                bitmap.setColor(.systemBlue, atX: x, y: y)
            }
        }

        let image = NSImage(size: NSSize(width: 8, height: 6))
        image.addRepresentation(bitmap)
        return image
    }

    private func fileURL(from writer: NSPasteboardWriting) -> URL? {
        guard let value = writer.pasteboardPropertyList(forType: .fileURL) as? String else {
            return nil
        }
        return URL(string: value)
    }
}
