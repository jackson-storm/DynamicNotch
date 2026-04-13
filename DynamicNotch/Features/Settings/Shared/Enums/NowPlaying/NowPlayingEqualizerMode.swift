//
//  NowPlayingEqualizerMode.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

enum NowPlayingEqualizerMode: String, CaseIterable {
    case classic
    case audioReactive

    var title: LocalizedStringKey {
        switch self {
        case .classic:
            return "Classic"
        case .audioReactive:
            return "Audio-reactive"
        }
    }

    static func resolved(_ rawValue: String?) -> NowPlayingEqualizerMode {
        switch rawValue {
        case NowPlayingEqualizerMode.audioReactive.rawValue:
            return .audioReactive
        default:
            return .classic
        }
    }
}
