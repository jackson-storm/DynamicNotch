//
//  FileConverterService.swift
//  DynamicNotch
//

import Foundation
@preconcurrency import AVFoundation
import ImageIO
import UniformTypeIdentifiers
internal import AppKit

enum FileConverterProcessRunner {
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
            
            var outputData = Data()
            let pipeReadQueue = DispatchQueue(label: "com.dynamicnotch.fileconverter.pipe")
            
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let available = handle.availableData
                if !available.isEmpty {
                    pipeReadQueue.sync {
                        outputData.append(available)
                    }
                }
            }
            
            try process.run()
            process.waitUntilExit()
            
            outputPipe.fileHandleForReading.readabilityHandler = nil
            try outputHandle?.close()
            
            let remainingData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            pipeReadQueue.sync {
                outputData.append(remainingData)
            }
            
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

final class FileConverterExportSessionBox: @unchecked Sendable {
    let session: AVAssetExportSession

    init(_ session: AVAssetExportSession) {
        self.session = session
    }
}

extension FileConverterVideoQuality {
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

final class FileConverterService: Sendable {
    static let shared = FileConverterService()
    
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

    func convert(
        item: FileConverterItem,
        to outputFormat: FileConverterOutputFormat,
        options: FileConverterConversionOptions
    ) async throws -> URL {
        let outputURL = try preparedOutputURL(for: item.url, format: outputFormat, options: options)
        
        if outputFormat.mediaKind == .archive {
            return try await convertArchive(
                at: item.url,
                isDirectory: item.isDirectory,
                to: outputFormat,
                outputURL: outputURL
            )
        }
        
        switch (item.mediaKind, outputFormat.mediaKind) {
        case (.image, .image):
            try convertImage(at: item.url, to: outputFormat, outputURL: outputURL, options: options)
            return outputURL
            
        case (.video, .video):
            return try await convertVideo(
                at: item.url,
                to: outputFormat,
                outputURL: outputURL,
                options: options
            )
            
        case (.audio, .audio):
            return try await convertAudio(
                at: item.url,
                to: outputFormat,
                outputURL: outputURL,
                options: options
            )
            
        default:
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "\(outputFormat.title) is not available for this file."]
            )
        }
    }
    
    func defaultFormat(for item: FileConverterItem) -> FileConverterOutputFormat {
        FileConverterOutputFormat.formats(for: item.mediaKind, isDirectory: item.isDirectory).first {
            $0.filenameExtensions.contains(item.fileExtension.lowercased()) == false
        } ?? item.mediaKind.defaultOutputFormat
    }
    
    func mediaKind(for url: URL, isDirectory: Bool) -> FileConverterMediaKind {
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
    
    func convertImage(
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
    
    func convertVideo(
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
    
    func convertAudio(
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
    
    func convertArchive(
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
    
    func preparedOutputURL(
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
