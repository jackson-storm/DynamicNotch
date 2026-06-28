//
//  ScreenRecordingContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/30/26.
//

import SwiftUI

enum ScreenRecordingEvent: Equatable {
    case started
    case stopped
}

struct ScreenRecordingContent: NotchContentProtocol {
    let id = NotchContentRegistry.ScreenRecording.active.id
    let usesDefaultStroke: Bool

    init(usesDefaultStroke: Bool = false) {
        self.usesDefaultStroke = usesDefaultStroke
    }

    @MainActor
    init(settingsViewModel: SettingsViewModel) {
        self.usesDefaultStroke =
            settingsViewModel.isDefaultActivityStrokeEnabled ||
            settingsViewModel.screenRecording.isScreenRecordingDefaultStrokeEnabled
    }

    var priority: Int { NotchContentRegistry.ScreenRecording.active.priority }
    var strokeColor: Color { usesDefaultStroke ? .white.opacity(0.2) : .red.opacity(0.3) }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 60, height: baseHeight)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(ScreenRecordingView())
    }
}
