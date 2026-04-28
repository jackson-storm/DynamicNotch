//
//  PlaybackSourceButton.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/28/26.
//

import SwiftUI

struct PlaybackSourceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.4 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
