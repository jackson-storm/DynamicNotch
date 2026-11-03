//
//  NotchScale.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/23/26.
//

import SwiftUI

struct NotchScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

struct IsNotchlessScreenKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

struct OnScrubbingChangedKey: EnvironmentKey {
    static let defaultValue: (Bool) -> Void = { _ in }
}

extension EnvironmentValues {
    var notchScale: CGFloat {
        get { self[NotchScaleKey.self] }
        set { self[NotchScaleKey.self] = newValue }
    }
    
    var isNotchlessScreen: Bool {
        get { self[IsNotchlessScreenKey.self] }
        set { self[IsNotchlessScreenKey.self] = newValue }
    }

    var onScrubbingChanged: (Bool) -> Void {
        get { self[OnScrubbingChangedKey.self] }
        set { self[OnScrubbingChangedKey.self] = newValue }
    }
}

