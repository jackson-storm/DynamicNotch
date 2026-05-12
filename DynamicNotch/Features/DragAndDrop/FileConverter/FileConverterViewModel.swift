//
//  FileConverterViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import Foundation
import Combine
@preconcurrency import AVFoundation
import ImageIO
import UniformTypeIdentifiers
internal import AppKit

enum FileConverterMediaKind {
    case image
    case video
    case audio
    case archive
    case generic
    
    var defaultOutputFormat: FileConverterOutputFormat {
        switch self {
        case .image:
            return .png
        case .video:
            return .mp4
        case .audio:
            return .m4a
        case .archive:
            return .tar
        case .generic:
            return .zip
        }
    }
}

enum FileConverterOutputFormat: String, CaseIterable, Identifiable {
    case png
    case jpeg
    case heic
    case webp
    case avif
    case tiff
    case gif
    case bmp
    case pdf
    case mp4
    case mov
    case m4v
    case aac
    case aiff
    case m4a
    case flac
    case mp3
    case ogg
    case wav
    case zip
    case tar
    case tarGzip
    case gzip
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        case .heic: return "HEIC"
        case .webp: return "WEBP"
        case .avif: return "AVIF"
        case .tiff: return "TIFF"
        case .gif: return "GIF"
        case .bmp: return "BMP"
        case .pdf: return "PDF"
        case .mp4: return "MP4"
        case .mov: return "MOV"
        case .m4v: return "M4V"
        case .aac: return "AAC"
        case .aiff: return "AIFF"
        case .m4a: return "M4A"
        case .flac: return "FLAC"
        case .mp3: return "MP3"
        case .ogg: return "OGG"
        case .wav: return "WAV"
        case .zip: return "ZIP"
        case .tar: return "TAR"
        case .tarGzip: return "TAR.GZ"
        case .gzip: return "GZ"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .heic: return "heic"
        case .webp: return "webp"
        case .avif: return "avif"
        case .tiff: return "tiff"
        case .gif: return "gif"
        case .bmp: return "bmp"
        case .pdf: return "pdf"
        case .mp4: return "mp4"
        case .mov: return "mov"
        case .m4v: return "m4v"
        case .aac: return "aac"
        case .aiff: return "aiff"
        case .m4a: return "m4a"
        case .flac: return "flac"
        case .mp3: return "mp3"
        case .ogg: return "ogg"
        case .wav: return "wav"
        case .zip: return "zip"
        case .tar: return "tar"
        case .tarGzip: return "tar.gz"
        case .gzip: return "gz"
        }
    }
    
    var filenameExtensions: [String] {
        switch self {
        case .jpeg:
            return ["jpg", "jpeg", "jpe", "jfif"]
        case .tiff:
            return ["tif", "tiff"]
        case .aiff:
            return ["aiff", "aif"]
        case .m4a:
            return ["m4a", "m4r"]
        case .ogg:
            return ["ogg", "oga", "opus"]
        case .wav:
            return ["wav"]
        case .tarGzip:
            return ["tar.gz", "tgz"]
        default:
            return [fileExtension]
        }
    }
    
    var mediaKind: FileConverterMediaKind {
        switch self {
        case .png, .jpeg, .heic, .webp, .avif, .tiff, .gif, .bmp, .pdf:
            return .image
        case .mp4, .mov, .m4v:
            return .video
        case .aac, .aiff, .m4a, .flac, .mp3, .ogg, .wav:
            return .audio
        case .zip, .tar, .tarGzip, .gzip:
            return .archive
        }
    }
    
    var imageTypeIdentifier: String? {
        switch self {
        case .png: return "public.png"
        case .jpeg: return "public.jpeg"
        case .heic: return "public.heic"
        case .webp: return "org.webmproject.webp"
        case .avif: return "public.avif"
        case .tiff: return "public.tiff"
        case .gif: return "com.compuserve.gif"
        case .bmp: return "com.microsoft.bmp"
        case .pdf: return "com.adobe.pdf"
        default: return nil
        }
    }
    
    var avFileType: AVFileType? {
        switch self {
        case .mp4: return .mp4
        case .mov: return .mov
        case .m4v: return .m4v
        default: return nil
        }
    }
    
    var afconvertFileFormat: String? {
        switch self {
        case .aac: return "adts"
        case .aiff: return "AIFF"
        case .m4a: return "m4af"
        case .flac: return "flac"
        case .mp3: return "MPG3"
        case .ogg: return "Oggf"
        case .wav: return "WAVE"
        default: return nil
        }
    }
    
    var afconvertDataFormat: String? {
        switch self {
        case .aac, .m4a:
            return "aac "
        case .aiff:
            return "BEI16"
        case .wav:
            return "LEI16"
        case .flac:
            return "flac"
        case .mp3:
            return ".mp3"
        case .ogg:
            return "opus"
        default:
            return nil
        }
    }

    var usesLossyImageQuality: Bool {
        switch self {
        case .jpeg, .heic, .webp, .avif:
            return true
        default:
            return false
        }
    }

    var usesCompressedAudioBitrate: Bool {
        switch self {
        case .aac, .m4a, .mp3, .ogg:
            return true
        default:
            return false
        }
    }
    
    static func formats(for kind: FileConverterMediaKind, isDirectory: Bool = false) -> [FileConverterOutputFormat] {
        switch kind {
        case .image:
            return imageFormats + archiveFormats(isDirectory: isDirectory)
        case .video:
            return videoFormats + archiveFormats(isDirectory: isDirectory)
        case .audio:
            return audioFormats + archiveFormats(isDirectory: isDirectory)
        case .archive, .generic:
            return archiveFormats(isDirectory: isDirectory)
        }
    }
    
    private static var imageFormats: [FileConverterOutputFormat] {
        allCases.filter { $0.mediaKind == .image && $0.isAvailableImageDestination }
    }
    
    private static var videoFormats: [FileConverterOutputFormat] {
        allCases.filter { $0.mediaKind == .video }
    }
    
    private static var audioFormats: [FileConverterOutputFormat] {
        allCases.filter { $0.mediaKind == .audio && $0.afconvertFileFormat != nil }
    }
    
    private static func archiveFormats(isDirectory: Bool) -> [FileConverterOutputFormat] {
        let formats: [FileConverterOutputFormat] = [.zip, .tar, .tarGzip]
        guard !isDirectory else { return formats }
        return formats + [.gzip]
    }
    
    private var isAvailableImageDestination: Bool {
        guard let imageTypeIdentifier else { return false }
        return Self.availableImageDestinationTypeIdentifiers.contains(imageTypeIdentifier)
    }
    
    private static let availableImageDestinationTypeIdentifiers: Set<String> = {
        let identifiers = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        return Set(identifiers)
    }()
}

struct FileConverterItem: Identifiable {
    let id = UUID()
    let url: URL
    let displayName: String
    let fileExtension: String
    let mediaKind: FileConverterMediaKind
    let isDirectory: Bool
    
    init(url: URL, mediaKind: FileConverterMediaKind, isDirectory: Bool) {
        let standardizedURL = url.standardizedFileURL
        self.url = standardizedURL
        self.displayName = standardizedURL.lastPathComponent.isEmpty ?
        standardizedURL.deletingLastPathComponent().lastPathComponent :
        standardizedURL.lastPathComponent
        self.fileExtension = standardizedURL.pathExtension.uppercased()
        self.mediaKind = mediaKind
        self.isDirectory = isDirectory
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

struct FileConverterConversionOptions {
    var outputLocation: FileConverterOutputLocation = .sameFolder
    var existingFileBehavior: FileConverterExistingFileBehavior = .createUniqueName
    var filenameSuffix: String = "-converted"
    var imageQuality: Double = 0.92
    var videoQuality: FileConverterVideoQuality = .high
    var audioQuality: FileConverterAudioQuality = .high

    init() {}

    init(settings: MediaAndFilesSettingsStore) {
        outputLocation = settings.fileConverterOutputLocation
        existingFileBehavior = settings.fileConverterExistingFileBehavior
        filenameSuffix = settings.fileConverterFilenameSuffix
        imageQuality = MediaAndFilesSettingsStore.clampFileConverterImageQuality(settings.fileConverterImageQuality)
        videoQuality = settings.fileConverterVideoQuality
        audioQuality = settings.fileConverterAudioQuality
    }
}

private extension FileConverterVideoQuality {
    var exportPresetNames: [String] {
        switch self {
        case .passthrough:
            return [
                AVAssetExportPresetPassthrough,
                AVAssetExportPresetHighestQuality
            ]
        case .high:
            return [
                AVAssetExportPresetHighestQuality,
                AVAssetExportPresetPassthrough
            ]
        case .medium:
            return [
                AVAssetExportPresetMediumQuality,
                AVAssetExportPresetHighestQuality,
                AVAssetExportPresetPassthrough
            ]
        case .small:
            return [
                AVAssetExportPresetLowQuality,
                AVAssetExportPresetMediumQuality,
                AVAssetExportPresetHighestQuality,
                AVAssetExportPresetPassthrough
            ]
        }
    }
}

private enum FileConverterProcessRunner {
    static func run(
        executablePath: String,
        arguments: [String],
        standardOutputURL: URL? = nil
    ) async throws {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            
            let outputPipe = Pipe()
            process.standardError = outputPipe
            
            var outputHandle: FileHandle?
            if let standardOutputURL {
                FileManager.default.createFile(atPath: standardOutputURL.path, contents: nil)
                outputHandle = try FileHandle(forWritingTo: standardOutputURL)
                process.standardOutput = outputHandle
            } else {
                process.standardOutput = outputPipe
            }
            
            try process.run()
            process.waitUntilExit()
            try outputHandle?.close()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let outputText = String(data: outputData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard process.terminationStatus == 0 else {
                throw NSError(
                    domain: "DynamicNotch.FileConverter",
                    code: Int(process.terminationStatus),
                    userInfo: [
                        NSLocalizedDescriptionKey: outputText?.isEmpty == false ?
                        outputText! :
                            "The native converter could not finish this file."
                    ]
                )
            }
        }.value
    }
}

private final class FileConverterExportSessionBox: @unchecked Sendable {
    let session: AVAssetExportSession

    init(_ session: AVAssetExportSession) {
        self.session = session
    }
}

@MainActor
final class FileConverterViewModel: ObservableObject {
    @Published private(set) var item: FileConverterItem?
    @Published var selectedFormat: FileConverterOutputFormat = .png
    @Published private(set) var status: FileConverterStatus = .idle
    
    private var conversionTask: Task<Void, Never>?
    
    private static let imageInputExtensions: Set<String> = [
        "png", "jpg", "jpeg", "jpe", "jfif", "heic", "webp", "avif",
        "tif", "tiff", "gif", "bmp", "pdf"
    ]
    
    private static let videoInputExtensions: Set<String> = [
        "mp4", "m4v", "mov", "qt", "mpg", "mpeg", "avi", "mkv", "webm", "wmv", "flv"
    ]
    
    private static let audioInputExtensions: Set<String> = [
        "mp3", "m4a", "m4r", "aac", "adts", "wav", "wave", "aif", "aiff",
        "flac", "ogg", "oga", "opus", "wma"
    ]
    
    private static let archiveInputExtensions: Set<String> = [
        "zip", "tar", "tgz", "gz", "rar", "7z"
    ]
    
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
    
    var availableFormats: [FileConverterOutputFormat] {
        guard let item else {
            return FileConverterOutputFormat.formats(for: .image)
        }
        
        return FileConverterOutputFormat.formats(
            for: item.mediaKind,
            isDirectory: item.isDirectory
        )
    }
    
    func setFile(_ url: URL) throws {
        let standardizedURL = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Choose a file or folder to convert."]
            )
        }
        
        let converterItem = FileConverterItem(
            url: standardizedURL,
            mediaKind: mediaKind(for: standardizedURL, isDirectory: isDirectory.boolValue),
            isDirectory: isDirectory.boolValue
        )
        item = converterItem
        selectedFormat = defaultFormat(for: converterItem)
        status = .idle
        onItemChange?(converterItem)
    }
    
    func convert(options: FileConverterConversionOptions) {
        guard let item, status != .converting else { return }
        
        conversionTask?.cancel()
        status = .converting
        
        let outputFormat = selectedFormat

        let outputURL: URL
        do {
            outputURL = try preparedOutputURL(for: item.url, format: outputFormat, options: options)
        } catch {
            handleConversionFailure(error.localizedDescription)
            return
        }
        
        if outputFormat.mediaKind == .archive {
            conversionTask = Task { [weak self] in
                await self?.runAsyncConversion {
                    try await self?.convertArchive(
                        at: item.url,
                        isDirectory: item.isDirectory,
                        to: outputFormat,
                        outputURL: outputURL
                    )
                }
            }
            return
        }
        
        switch (item.mediaKind, outputFormat.mediaKind) {
        case (.image, .image):
            do {
                try convertImage(at: item.url, to: outputFormat, outputURL: outputURL, options: options)
                handleConversionSuccess(outputURL)
            } catch {
                handleConversionFailure(error.localizedDescription)
            }
            
        case (.video, .video):
            conversionTask = Task { [weak self] in
                await self?.runAsyncConversion {
                    try await self?.convertVideo(
                        at: item.url,
                        to: outputFormat,
                        outputURL: outputURL,
                        options: options
                    )
                }
            }
            
        case (.audio, .audio):
            conversionTask = Task { [weak self] in
                await self?.runAsyncConversion {
                    try await self?.convertAudio(
                        at: item.url,
                        to: outputFormat,
                        outputURL: outputURL,
                        options: options
                    )
                }
            }
            
        default:
            handleConversionFailure("\(outputFormat.title) is not available for this file.")
        }
    }
    
    @MainActor
    func chooseFileFromFinder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.prompt = "Choose"
        panel.message = "Choose a file to convert"
        
        panel.allowedContentTypes = [
            .image,
            .movie,
            .video,
            .audio,
            .archive,
            .zip,
            .folder
        ]
        
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        
        do {
            try setFile(url)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
    
    func revealConvertedFile() {
        guard case .converted(let outputURL) = status else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }
    
    func clear() {
        conversionTask?.cancel()
        conversionTask = nil
        item = nil
        status = .idle
        onItemChange?(nil)
    }
    
    private func runAsyncConversion(_ conversion: () async throws -> URL?) async {
        do {
            guard let outputURL = try await conversion() else { return }
            guard !Task.isCancelled else { return }
            handleConversionSuccess(outputURL)
        } catch {
            guard !Task.isCancelled else { return }
            handleConversionFailure(error.localizedDescription)
        }
    }

    private func handleConversionSuccess(_ outputURL: URL) {
        conversionTask = nil
        status = .converted(outputURL)
    }

    private func handleConversionFailure(_ message: String) {
        conversionTask = nil
        status = .failed(message)
    }
    
    private func defaultFormat(for item: FileConverterItem) -> FileConverterOutputFormat {
        FileConverterOutputFormat.formats(for: item.mediaKind, isDirectory: item.isDirectory).first {
            $0.filenameExtensions.contains(item.fileExtension.lowercased()) == false
        } ?? item.mediaKind.defaultOutputFormat
    }
    
    private func convertImage(
        at sourceURL: URL,
        to format: FileConverterOutputFormat,
        outputURL: URL,
        options: FileConverterConversionOptions
    ) throws {
        guard format.mediaKind == .image,
              let imageTypeIdentifier = format.imageTypeIdentifier else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Choose an image output format."]
            )
        }
        
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Could not read this image."]
            )
        }
        
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            imageTypeIdentifier as CFString,
            1,
            nil
        ) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: "Could not create this image format."]
            )
        }
        
        let properties: CFDictionary?
        if format.usesLossyImageQuality {
            properties = [
                kCGImageDestinationLossyCompressionQuality as String: options.imageQuality
            ] as CFDictionary
        } else {
            properties = nil
        }
        
        CGImageDestinationAddImage(destination, image, properties)
        
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 6,
                userInfo: [NSLocalizedDescriptionKey: "Could not encode this image."]
            )
        }
    }
    
    private func convertVideo(
        at sourceURL: URL,
        to format: FileConverterOutputFormat,
        outputURL: URL,
        options: FileConverterConversionOptions
    ) async throws -> URL {
        guard let outputFileType = format.avFileType else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 7,
                userInfo: [NSLocalizedDescriptionKey: "Choose a video output format."]
            )
        }
        
        let asset = AVURLAsset(url: sourceURL)
        
        guard let exportSession = options.videoQuality.exportPresetNames.lazy.compactMap({
            AVAssetExportSession(asset: asset, presetName: $0)
        }).first else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 8,
                userInfo: [NSLocalizedDescriptionKey: "This media file cannot be exported by macOS."]
            )
        }
        
        guard exportSession.supportedFileTypes.contains(outputFileType) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 9,
                userInfo: [NSLocalizedDescriptionKey: "\(format.title) is not available for this file."]
            )
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType
        exportSession.shouldOptimizeForNetworkUse = true
        
        let exportSessionBox = FileConverterExportSessionBox(exportSession)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                let exportSession = exportSessionBox.session

                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: ())
                    
                case .failed:
                    continuation.resume(
                        throwing: exportSession.error ??
                        NSError(
                            domain: "DynamicNotch.FileConverter",
                            code: 10,
                            userInfo: [NSLocalizedDescriptionKey: "Could not export this media file."]
                        )
                    )
                    
                case .cancelled:
                    continuation.resume(throwing: CancellationError())
                    
                default:
                    continuation.resume(
                        throwing: NSError(
                            domain: "DynamicNotch.FileConverter",
                            code: 11,
                            userInfo: [NSLocalizedDescriptionKey: "Media export finished in an unknown state."]
                        )
                    )
                }
            }
        }
        
        return outputURL
    }
    
    private func convertAudio(
        at sourceURL: URL,
        to format: FileConverterOutputFormat,
        outputURL: URL,
        options: FileConverterConversionOptions
    ) async throws -> URL {
        guard let fileFormat = format.afconvertFileFormat else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 12,
                userInfo: [NSLocalizedDescriptionKey: "Choose an audio output format."]
            )
        }
        
        var arguments = ["-f", fileFormat]
        if let dataFormat = format.afconvertDataFormat {
            arguments += ["-d", dataFormat]
        }
        if let bitrate = options.audioQuality.bitrate,
           format.usesCompressedAudioBitrate {
            arguments += ["-b", "\(bitrate)"]
        }
        arguments += [sourceURL.path, outputURL.path]
        
        try await FileConverterProcessRunner.run(
            executablePath: "/usr/bin/afconvert",
            arguments: arguments
        )
        return outputURL
    }
    
    private func convertArchive(
        at sourceURL: URL,
        isDirectory: Bool,
        to format: FileConverterOutputFormat,
        outputURL: URL
    ) async throws -> URL {
        let parentPath = sourceURL.deletingLastPathComponent().path
        let itemName = sourceURL.lastPathComponent
        
        switch format {
        case .zip:
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/ditto",
                arguments: ["-c", "-k", "--sequesterRsrc", "--keepParent", sourceURL.path, outputURL.path]
            )
            
        case .tar:
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/tar",
                arguments: ["-cf", outputURL.path, "-C", parentPath, "--", itemName]
            )
            
        case .tarGzip:
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/tar",
                arguments: ["-czf", outputURL.path, "-C", parentPath, "--", itemName]
            )
            
        case .gzip:
            try validateSingleFileArchiveSource(isDirectory: isDirectory, format: format)
            try await FileConverterProcessRunner.run(
                executablePath: "/usr/bin/gzip",
                arguments: ["-c", sourceURL.path],
                standardOutputURL: outputURL
            )
            
        default:
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 13,
                userInfo: [NSLocalizedDescriptionKey: "Choose an archive output format."]
            )
        }
        
        return outputURL
    }
    
    private func validateSingleFileArchiveSource(
        isDirectory: Bool,
        format: FileConverterOutputFormat
    ) throws {
        guard !isDirectory else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 14,
                userInfo: [NSLocalizedDescriptionKey: "\(format.title) can archive single files only. Use TAR or ZIP for folders."]
            )
        }
    }
    
    private func mediaKind(for url: URL, isDirectory: Bool) -> FileConverterMediaKind {
        guard !isDirectory else { return .generic }
        
        let pathExtension = url.pathExtension.lowercased()
        let contentType = UTType(filenameExtension: pathExtension)
        
        if Self.archiveInputExtensions.contains(pathExtension) {
            return .archive
        }
        
        if contentType?.conforms(to: .image) == true ||
            Self.imageInputExtensions.contains(pathExtension) ||
            NSImage(contentsOf: url) != nil {
            return .image
        }
        
        if contentType?.conforms(to: .movie) == true ||
            contentType?.conforms(to: .video) == true ||
            Self.videoInputExtensions.contains(pathExtension) {
            return .video
        }
        
        if contentType?.conforms(to: .audio) == true ||
            Self.audioInputExtensions.contains(pathExtension) {
            return .audio
        }
        
        return .generic
    }
    
    private func preparedOutputURL(
        for sourceURL: URL,
        format: FileConverterOutputFormat,
        options: FileConverterConversionOptions
    ) throws -> URL {
        let outputURL: URL

        if options.outputLocation == .askEveryTime {
            outputURL = try askForOutputURL(sourceURL: sourceURL, format: format, options: options)
        } else {
            let preferredURL = preferredOutputURL(sourceURL: sourceURL, format: format, options: options)
            outputURL = try resolvedOutputURL(
                preferredURL,
                sourceURL: sourceURL,
                format: format,
                options: options
            )
        }

        guard outputURL.standardizedFileURL != sourceURL.standardizedFileURL else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 15,
                userInfo: [NSLocalizedDescriptionKey: "Choose a different output file."]
            )
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        return outputURL
    }

    private func preferredOutputURL(
        sourceURL: URL,
        format: FileConverterOutputFormat,
        options: FileConverterConversionOptions
    ) -> URL {
        let directory = outputDirectory(for: sourceURL, options: options)
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let suffix = normalizedFilenameSuffix(options.filenameSuffix)
        let preferredName = "\(baseName)\(suffix)"

        return directory
            .appendingPathComponent(preferredName.isEmpty ? baseName : preferredName)
            .appendingPathExtension(format.fileExtension)
    }

    private func resolvedOutputURL(
        _ preferredURL: URL,
        sourceURL: URL,
        format: FileConverterOutputFormat,
        options: FileConverterConversionOptions
    ) throws -> URL {
        guard FileManager.default.fileExists(atPath: preferredURL.path) else {
            return preferredURL
        }

        switch options.existingFileBehavior {
        case .createUniqueName:
            return uniqueOutputURL(from: preferredURL, format: format)
        case .replace:
            return preferredURL
        case .ask:
            return try askForOutputURL(sourceURL: sourceURL, format: format, options: options)
        }
    }

    private func uniqueOutputURL(from preferredURL: URL, format: FileConverterOutputFormat) -> URL {
        let directory = preferredURL.deletingLastPathComponent()
        let baseName = preferredURL.deletingPathExtension().lastPathComponent
        var candidate = preferredURL
        var suffix = 1
        
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(baseName)-\(suffix)")
                .appendingPathExtension(format.fileExtension)
            suffix += 1
        }
        
        return candidate
    }

    private func askForOutputURL(
        sourceURL: URL,
        format: FileConverterOutputFormat,
        options: FileConverterConversionOptions
    ) throws -> URL {
        let panel = NSSavePanel()
        let preferredURL = preferredOutputURL(sourceURL: sourceURL, format: format, options: options)

        panel.directoryURL = preferredURL.deletingLastPathComponent()
        panel.nameFieldStringValue = preferredURL.lastPathComponent
        panel.canCreateDirectories = true
        panel.prompt = "Convert"
        panel.message = "Choose where to save the converted file."

        guard panel.runModal() == .OK, let url = panel.url else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 16,
                userInfo: [NSLocalizedDescriptionKey: "Conversion was cancelled."]
            )
        }

        return url
    }

    private func outputDirectory(for sourceURL: URL, options: FileConverterConversionOptions) -> URL {
        switch options.outputLocation {
        case .sameFolder, .askEveryTime:
            return sourceURL.deletingLastPathComponent()
        case .downloads:
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ??
            sourceURL.deletingLastPathComponent()
        }
    }

    private func normalizedFilenameSuffix(_ suffix: String) -> String {
        suffix.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#if DEBUG
extension FileConverterViewModel {
    func showDebugConvertingStatus() {
        conversionTask?.cancel()
        conversionTask = nil
        status = .converting
    }

    func showDebugFailedStatus() {
        conversionTask?.cancel()
        conversionTask = nil
        status = .failed("Debug conversion failed.")
    }
}
#endif
