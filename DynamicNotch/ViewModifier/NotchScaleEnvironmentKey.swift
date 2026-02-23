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

extension EnvironmentValues {
    var notchScale: CGFloat {
        get { self[NotchScaleKey.self] }
        set { self[NotchScaleKey.self] = newValue }
    }
}
