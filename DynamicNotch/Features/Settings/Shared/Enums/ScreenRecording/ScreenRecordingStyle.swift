//
//  ScreenRecordingStyle.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 8/29/26.
//

import SwiftUI

enum ScreenRecordingStyle: String, CaseIterable {
    case compact
    case detailed

    var title: LocalizedStringKey {
        switch self {
        case .compact:
            return "settings.screenRecording.appearanceStyle.compact"
        case .detailed:
            return "settings.screenRecording.appearanceStyle.detailed"
        }
    }

    static func resolved(_ rawValue: String?) -> ScreenRecordingStyle {
        ScreenRecordingStyle(rawValue: rawValue ?? ScreenRecordingStyle.detailed.rawValue) ?? .detailed
    }
}
