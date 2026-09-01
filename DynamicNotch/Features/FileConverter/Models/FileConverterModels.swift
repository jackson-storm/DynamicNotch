//
//  FileConverterModels.swift
//  DynamicNotch
//

import Foundation
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
internal import AppKit

enum FileConverterMediaKind: Equatable {
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
