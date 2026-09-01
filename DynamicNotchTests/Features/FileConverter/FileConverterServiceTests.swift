//
//  FileConverterServiceTests.swift
//  DynamicNotchTests
//

import XCTest
@testable import DynamicNotch

final class FileConverterServiceTests: XCTestCase {
    private var service: FileConverterService!
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        service = FileConverterService.shared
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileConverterServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        service = nil
        tempDirectory = nil
        super.tearDown()
    }

    // MARK: - Media Kind Detection

    func testMediaKindDetectionForImages() {
        let pngURL = URL(fileURLWithPath: "/tmp/sample.png")
        let jpgURL = URL(fileURLWithPath: "/tmp/sample.jpg")
        let heicURL = URL(fileURLWithPath: "/tmp/sample.heic")
        let webpURL = URL(fileURLWithPath: "/tmp/sample.webp")

        XCTAssertEqual(service.mediaKind(for: pngURL, isDirectory: false), .image)
        XCTAssertEqual(service.mediaKind(for: jpgURL, isDirectory: false), .image)
        XCTAssertEqual(service.mediaKind(for: heicURL, isDirectory: false), .image)
        XCTAssertEqual(service.mediaKind(for: webpURL, isDirectory: false), .image)
    }

    func testMediaKindDetectionForVideos() {
        let mp4URL = URL(fileURLWithPath: "/tmp/video.mp4")
        let movURL = URL(fileURLWithPath: "/tmp/video.mov")
        let mkvURL = URL(fileURLWithPath: "/tmp/video.mkv")

        XCTAssertEqual(service.mediaKind(for: mp4URL, isDirectory: false), .video)
        XCTAssertEqual(service.mediaKind(for: movURL, isDirectory: false), .video)
        XCTAssertEqual(service.mediaKind(for: mkvURL, isDirectory: false), .video)
    }

    func testMediaKindDetectionForAudio() {
        let mp3URL = URL(fileURLWithPath: "/tmp/audio.mp3")
        let m4aURL = URL(fileURLWithPath: "/tmp/audio.m4a")
        let wavURL = URL(fileURLWithPath: "/tmp/audio.wav")
        let flacURL = URL(fileURLWithPath: "/tmp/audio.flac")

        XCTAssertEqual(service.mediaKind(for: mp3URL, isDirectory: false), .audio)
        XCTAssertEqual(service.mediaKind(for: m4aURL, isDirectory: false), .audio)
        XCTAssertEqual(service.mediaKind(for: wavURL, isDirectory: false), .audio)
        XCTAssertEqual(service.mediaKind(for: flacURL, isDirectory: false), .audio)
    }

    func testMediaKindDetectionForArchives() {
        let zipURL = URL(fileURLWithPath: "/tmp/archive.zip")
        let tarURL = URL(fileURLWithPath: "/tmp/archive.tar")
        let gzURL = URL(fileURLWithPath: "/tmp/archive.gz")

        XCTAssertEqual(service.mediaKind(for: zipURL, isDirectory: false), .archive)
        XCTAssertEqual(service.mediaKind(for: tarURL, isDirectory: false), .archive)
        XCTAssertEqual(service.mediaKind(for: gzURL, isDirectory: false), .archive)
    }

    func testMediaKindDetectionForDirectory() {
        let folderURL = URL(fileURLWithPath: "/tmp/MyFolder")
        XCTAssertEqual(service.mediaKind(for: folderURL, isDirectory: true), .generic)
    }

    // MARK: - Output Formats

    func testAvailableFormatsForDirectoryExcludesGzip() {
        let formats = FileConverterOutputFormat.formats(for: .generic, isDirectory: true)
        XCTAssertTrue(formats.contains(.zip))
        XCTAssertTrue(formats.contains(.tar))
        XCTAssertTrue(formats.contains(.tarGzip))
        XCTAssertFalse(formats.contains(.gzip), "Gzip should not be available for directories")
    }

    func testAvailableFormatsForFileIncludesGzip() {
        let formats = FileConverterOutputFormat.formats(for: .generic, isDirectory: false)
        XCTAssertTrue(formats.contains(.gzip), "Gzip should be available for single files")
    }

    func testDefaultFormatDiffersFromCurrentFileExtension() {
        let imageItem = FileConverterItem(
            url: URL(fileURLWithPath: "/tmp/sample.png"),
            mediaKind: .image,
            isDirectory: false
        )
        let defaultFormat = service.defaultFormat(for: imageItem)
        XCTAssertNotEqual(defaultFormat, .png, "Default format should differ from input extension if possible")
    }

    // MARK: - URL Resolution

    func testPreparedOutputURLCreatesUniqueNameWhenFileExists() throws {
        let sourceFile = tempDirectory.appendingPathComponent("image.png")
        try "fake-image".write(to: sourceFile, atomically: true, encoding: .utf8)

        // Pre-create the expected output file
        let existingTarget = tempDirectory.appendingPathComponent("image-converted.jpg")
        try "existing-content".write(to: existingTarget, atomically: true, encoding: .utf8)

        var options = FileConverterConversionOptions()
        options.outputLocation = .sameFolder
        options.existingFileBehavior = .createUniqueName
        options.filenameSuffix = "-converted"

        let resolvedURL = try service.preparedOutputURL(for: sourceFile, format: .jpeg, options: options)

        XCTAssertNotEqual(resolvedURL.path, existingTarget.path)
        XCTAssertTrue(resolvedURL.lastPathComponent.contains("-1.jpg"))
    }

    func testPreparedOutputURLThrowsErrorWhenTargetMatchesSource() {
        let sourceFile = tempDirectory.appendingPathComponent("document.pdf")

        var options = FileConverterConversionOptions()
        options.outputLocation = .sameFolder
        options.existingFileBehavior = .replace
        options.filenameSuffix = "" // No suffix: target would be document.pdf

        XCTAssertThrowsError(
            try service.preparedOutputURL(for: sourceFile, format: .pdf, options: options)
        ) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "DynamicNotch.FileConverter")
            XCTAssertEqual(nsError.code, 15)
        }
    }
}
