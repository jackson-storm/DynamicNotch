//
//  FileConverterViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import Foundation
import Combine
internal import AppKit

enum FileConverterOutputFormat: String, CaseIterable, Identifiable {
    case png
    case jpeg
    case tiff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .png:
            return "PNG"
        case .jpeg:
            return "JPEG"
        case .tiff:
            return "TIFF"
        }
    }

    var fileExtension: String {
        switch self {
        case .png:
            return "png"
        case .jpeg:
            return "jpg"
        case .tiff:
            return "tiff"
        }
    }

    var bitmapFileType: NSBitmapImageRep.FileType {
        switch self {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .tiff:
            return .tiff
        }
    }
}

struct FileConverterItem: Identifiable {
    let id = UUID()
    let url: URL
    let displayName: String
    let fileExtension: String

    init(url: URL) {
        let standardizedURL = url.standardizedFileURL
        self.url = standardizedURL
        self.displayName = standardizedURL.lastPathComponent.isEmpty ?
        standardizedURL.deletingLastPathComponent().lastPathComponent :
        standardizedURL.lastPathComponent
        self.fileExtension = standardizedURL.pathExtension.uppercased()
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

enum FileConverterStatus: Equatable {
    case idle
    case converting
    case converted(URL)
    case failed(String)
}

@MainActor
final class FileConverterViewModel: ObservableObject {
    @Published private(set) var item: FileConverterItem?
    @Published var selectedFormat: FileConverterOutputFormat = .png
    @Published private(set) var status: FileConverterStatus = .idle

    var onItemChange: (@MainActor (FileConverterItem?) -> Void)? {
        didSet {
            onItemChange?(item)
        }
    }

    var hasItem: Bool {
        item != nil
    }

    var isConverting: Bool {
        status == .converting
    }

    var isConverted: Bool {
        if case .converted = status {
            return true
        }

        return false
    }

    func setFile(_ url: URL) throws {
        let standardizedURL = url.standardizedFileURL
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Choose a single file to convert."]
            )
        }

        guard NSImage(contentsOf: standardizedURL) != nil else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "This first version converts image files only."]
            )
        }

        let converterItem = FileConverterItem(url: standardizedURL)
        item = converterItem
        selectedFormat = defaultFormat(for: converterItem)
        status = .idle
        onItemChange?(converterItem)
    }

    func convert() {
        guard let item, status != .converting else { return }

        status = .converting

        do {
            let outputURL = try convertImage(at: item.url, to: selectedFormat)
            status = .converted(outputURL)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func revealConvertedFile() {
        guard case .converted(let outputURL) = status else { return }

        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }

    func clear() {
        item = nil
        status = .idle
        onItemChange?(nil)
    }

    private func defaultFormat(for item: FileConverterItem) -> FileConverterOutputFormat {
        FileConverterOutputFormat.allCases.first {
            $0.fileExtension.uppercased() != item.fileExtension
        } ?? .png
    }

    private func convertImage(at sourceURL: URL, to format: FileConverterOutputFormat) throws -> URL {
        guard let image = NSImage(contentsOf: sourceURL),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Could not read this image."]
            )
        }

        let properties: [NSBitmapImageRep.PropertyKey: Any]
        if format == .jpeg {
            properties = [.compressionFactor: 0.92]
        } else {
            properties = [:]
        }

        guard let outputData = bitmap.representation(using: format.bitmapFileType, properties: properties) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Could not encode this image."]
            )
        }

        let outputURL = uniqueOutputURL(for: sourceURL, format: format)
        try outputData.write(to: outputURL, options: .atomic)
        return outputURL
    }

    private func uniqueOutputURL(for sourceURL: URL, format: FileConverterOutputFormat) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let preferredName = "\(baseName)-converted"
        var candidate = directory
            .appendingPathComponent(preferredName)
            .appendingPathExtension(format.fileExtension)
        var suffix = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(preferredName)-\(suffix)")
                .appendingPathExtension(format.fileExtension)
            suffix += 1
        }

        return candidate
    }
}
