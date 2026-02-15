//
//  WindowHoverModifier.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

struct WindowHoverModifier: ViewModifier {
    weak var window: NSWindow?
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                window?.ignoresMouseEvents = !hovering
            }
    }
}
