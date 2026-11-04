//
//  ScreenshotImageLoaderTests.swift
//  DynamicNotchTests
//

import XCTest
import ImageIO
import UniformTypeIdentifiers
@testable import DynamicNotch

final class ScreenshotImageLoaderTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScreenshotImageLoaderTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        super.tearDown()
    }

    func testLoadPNGReturnsFullImageAndPreview() throws {
        let url = tempDirectory.appendingPathComponent("Screenshot.png")
        try ScreenshotTestImages.write(width: 3000, height: 1800, type: UTType.png.identifier, to: url)

        let loaded = try XCTUnwrap(ScreenshotImageLoader.load(contentsOf: url, previewMaxPixelSize: 1024))

        assertPixels(of: loaded.image, width: 3000, height: 1800)
        assertPixels(of: loaded.preview, width: 1024, height: 614)
        XCTAssertEqual(loaded.image.size.width / loaded.image.size.height, 3000.0 / 1800.0, accuracy: 0.01)
        XCTAssertEqual(loaded.preview.size.width / loaded.preview.size.height, 3000.0 / 1800.0, accuracy: 0.01)
    }

    func testLoadHEICReturnsFullImageAndPreview() throws {
        let url = tempDirectory.appendingPathComponent("Screenshot.heic")
        do {
            try ScreenshotTestImages.write(width: 3000, height: 1800, type: "public.heic", to: url)
        } catch {
            throw XCTSkip("HEIC encoding is unavailable on this host: \(error)")
        }

        let loaded = try XCTUnwrap(ScreenshotImageLoader.load(contentsOf: url, previewMaxPixelSize: 1024))

        assertPixels(of: loaded.image, width: 3000, height: 1800)
        assertPixels(of: loaded.preview, width: 1024, height: 614)
    }

    func testLoadUsesTheFileDPIForThePointSize() throws {
        let url = tempDirectory.appendingPathComponent("Screenshot@2x.png")
        try ScreenshotTestImages.write(width: 3000, height: 1800, type: UTType.png.identifier, dpi: 144, to: url)

        let loaded = try XCTUnwrap(ScreenshotImageLoader.load(contentsOf: url, previewMaxPixelSize: 1024))

        XCTAssertEqual(loaded.image.size.width, 1500, accuracy: 0.5)
        XCTAssertEqual(loaded.image.size.height, 900, accuracy: 0.5)
        XCTAssertEqual(loaded.image.size, NSImage(contentsOf: url)?.size)
        XCTAssertEqual(loaded.preview.size.width, 512, accuracy: 1)
    }

    func testLoadOfTruncatedFileReturnsNil() throws {
        let fullURL = tempDirectory.appendingPathComponent("Full.png")
        try ScreenshotTestImages.write(width: 3000, height: 1800, type: UTType.png.identifier, to: fullURL)
        let truncatedURL = tempDirectory.appendingPathComponent("Truncated.png")
        try Data(try Data(contentsOf: fullURL).prefix(1000)).write(to: truncatedURL)

        XCTAssertNil(ScreenshotImageLoader.load(contentsOf: truncatedURL, previewMaxPixelSize: 1024))
    }

    func testLoadDoesNotDecodeTheFullImageUpFront() throws {
        let url = tempDirectory.appendingPathComponent("Lazy.png")
        try ScreenshotTestImages.write(width: 3000, height: 1800, type: UTType.png.identifier, to: url)

        let loaded = try XCTUnwrap(ScreenshotImageLoader.load(contentsOf: url, previewMaxPixelSize: 1024))
        let bitmap = try XCTUnwrap(loaded.image.representations.first as? NSBitmapImageRep)
        XCTAssertEqual(bitmap.pixelsWide, 3000)
        XCTAssertEqual(bitmap.pixelsHigh, 1800)
        XCTAssertEqual(loaded.image.size, NSSize(width: 3000, height: 1800))
        XCTAssertEqual(loaded.preview.cgImage(forProposedRect: nil, context: nil, hints: nil)?.width, 1024)
    }

    func testLoadOfMissingFileReturnsNil() {
        let url = tempDirectory.appendingPathComponent("Missing.png")
        XCTAssertNil(ScreenshotImageLoader.load(contentsOf: url, previewMaxPixelSize: 1024))
    }

    func testMakePreviewScalesTheLongSideTo1024() throws {
        let image = NSImage(cgImage: try ScreenshotTestImages.makeCGImage(width: 3000, height: 1800),
                            size: NSSize(width: 3000, height: 1800))

        let preview = ScreenshotImageLoader.makePreview(from: image, maxPixelSize: 1024)

        assertPixels(of: preview, width: 1024, height: 614)
        XCTAssertEqual(preview.size.width / preview.size.height, 3000.0 / 1800.0, accuracy: 0.01)
    }

    func testMakePreviewDoesNotUpscale() throws {
        let image = NSImage(cgImage: try ScreenshotTestImages.makeCGImage(width: 400, height: 300),
                            size: NSSize(width: 400, height: 300))

        let preview = ScreenshotImageLoader.makePreview(from: image, maxPixelSize: 1024)

        assertPixels(of: preview, width: 400, height: 300)
    }

    private func assertPixels(
        of image: NSImage,
        width: Int,
        height: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            XCTFail("Image has no bitmap", file: file, line: line)
            return
        }
        XCTAssertEqual(Double(cgImage.width), Double(width), accuracy: 1, file: file, line: line)
        XCTAssertEqual(Double(cgImage.height), Double(height), accuracy: 1, file: file, line: line)
    }
}

enum ScreenshotTestImages {
    struct EncodingError: Error {}

    static func makeCGImage(width: Int, height: Int) throws -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw EncodingError() }
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 1))
        context.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        guard let image = context.makeImage() else { throw EncodingError() }
        return image
    }

    static func write(width: Int, height: Int, type: String, dpi: Int = 72, to url: URL) throws {
        let image = try makeCGImage(width: width, height: height)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type as CFString, 1, nil) else {
            throw EncodingError()
        }
        let properties = [kCGImagePropertyDPIWidth: dpi, kCGImagePropertyDPIHeight: dpi] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { throw EncodingError() }
    }
}
