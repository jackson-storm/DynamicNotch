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
            return "Copy"
        case .moveOriginals:
            return "Move originals"
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
            return "Horizontal"
        case .vertical:
            return "Vertical"
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
            return "Same folder"
        case .downloads:
            return "Downloads"
        case .askEveryTime:
            return "Ask every time"
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
            return "Create unique name"
        case .replace:
            return "Replace"
        case .ask:
            return "Ask"
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
            return "Passthrough"
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .small:
            return "Small"
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
            return "Source"
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .small:
            return "Small"
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
