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
