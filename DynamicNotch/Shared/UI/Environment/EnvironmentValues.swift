//
//  NotchScale.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/23/26.
//

import SwiftUI

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

