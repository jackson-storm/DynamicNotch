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
