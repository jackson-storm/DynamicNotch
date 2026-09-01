//
//  FileTrayUsageMode.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/5/26.
//

import SwiftUI

enum FileTrayUsageMode: String, CaseIterable {
    case copy
    case moveOriginals = "folder"

    var title: LocalizedStringKey {
        switch self {
        case .copy:
            return "settings.drop.fileTrayUsageMode.copy"
        case .moveOriginals:
            return "settings.drop.fileTrayUsageMode.moveOriginals"
        }
    }

    static func resolved(_ rawValue: String?) -> FileTrayUsageMode {
        switch rawValue {
        case FileTrayUsageMode.moveOriginals.rawValue:
            return .moveOriginals
        default:
            return .copy
        }
    }
}

enum FileTrayScrollDirection: String, CaseIterable, Equatable {
    case horizontal
    case vertical

    var title: LocalizedStringKey {
        switch self {
        case .horizontal:
            return "settings.drop.fileTrayScrollDirection.horizontal"
        case .vertical:
            return "settings.drop.fileTrayScrollDirection.vertical"
        }
    }

    var scrollAxis: Axis.Set {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }

    static func resolved(_ rawValue: String?) -> FileTrayScrollDirection {
        switch rawValue {
        case FileTrayScrollDirection.vertical.rawValue:
            return .vertical
        default:
            return .horizontal
        }
    }
}

enum FileConverterOutputLocation: String, CaseIterable, Equatable {
    case sameFolder
    case downloads
    case askEveryTime

    var title: LocalizedStringKey {
        switch self {
        case .sameFolder:
            return "settings.fileConverter.outputLocation.sameFolder"
        case .downloads:
            return "settings.fileConverter.outputLocation.downloads"
        case .askEveryTime:
            return "settings.fileConverter.outputLocation.askEveryTime"
        }
    }

    static func resolved(_ rawValue: String?) -> FileConverterOutputLocation {
        switch rawValue {
        case FileConverterOutputLocation.downloads.rawValue:
            return .downloads
        case FileConverterOutputLocation.askEveryTime.rawValue:
            return .askEveryTime
        default:
            return .sameFolder
        }
    }
}

enum FileConverterExistingFileBehavior: String, CaseIterable, Equatable {
    case createUniqueName
    case replace
    case ask

    var title: LocalizedStringKey {
        switch self {
        case .createUniqueName:
            return "settings.fileConverter.existingFileBehavior.createUniqueName"
        case .replace:
            return "settings.fileConverter.existingFileBehavior.replace"
        case .ask:
            return "settings.fileConverter.existingFileBehavior.ask"
        }
    }

    static func resolved(_ rawValue: String?) -> FileConverterExistingFileBehavior {
        switch rawValue {
        case FileConverterExistingFileBehavior.replace.rawValue:
            return .replace
        case FileConverterExistingFileBehavior.ask.rawValue:
            return .ask
        default:
            return .createUniqueName
        }
    }
}

enum FileConverterVideoQuality: String, CaseIterable, Equatable {
    case passthrough
    case high
    case medium
    case small

    var title: LocalizedStringKey {
        switch self {
        case .passthrough:
            return "settings.fileConverter.videoQuality.passthrough"
        case .high:
            return "settings.fileConverter.videoQuality.high"
        case .medium:
            return "settings.fileConverter.videoQuality.medium"
        case .small:
            return "settings.fileConverter.videoQuality.small"
        }
    }

    static func resolved(_ rawValue: String?) -> FileConverterVideoQuality {
        switch rawValue {
        case FileConverterVideoQuality.passthrough.rawValue:
            return .passthrough
        case FileConverterVideoQuality.medium.rawValue:
            return .medium
        case FileConverterVideoQuality.small.rawValue:
            return .small
        default:
            return .high
        }
    }
}

enum FileConverterAudioQuality: String, CaseIterable, Equatable {
    case source
    case high
    case medium
    case small

    var title: LocalizedStringKey {
        switch self {
        case .source:
            return "settings.fileConverter.audioQuality.source"
        case .high:
            return "settings.fileConverter.videoQuality.high"
        case .medium:
            return "settings.fileConverter.videoQuality.medium"
        case .small:
            return "settings.fileConverter.videoQuality.small"
        }
    }

    var bitrate: Int? {
        switch self {
        case .source:
            return nil
        case .high:
            return 256_000
        case .medium:
            return 160_000
        case .small:
            return 96_000
        }
    }

    static func resolved(_ rawValue: String?) -> FileConverterAudioQuality {
        switch rawValue {
        case FileConverterAudioQuality.source.rawValue:
            return .source
        case FileConverterAudioQuality.medium.rawValue:
            return .medium
        case FileConverterAudioQuality.small.rawValue:
            return .small
        default:
            return .high
        }
    }
}
