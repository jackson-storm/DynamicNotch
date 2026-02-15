//
//  View.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

extension View {
    func notchPressable(isPressed: Binding<Bool>) -> some View {
        modifier(NotchPressModifier(isPressed: isPressed))
    }

    func windowHover(_ window: NSWindow?) -> some View {
        modifier(WindowHoverModifier(window: window))
    }
}
