//
//  OnScrubbingChangedKey.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/8/26.
//

import SwiftUI

struct OnScrubbingChangedKey: EnvironmentKey {
    static let defaultValue: (Bool) -> Void = { _ in }
}
