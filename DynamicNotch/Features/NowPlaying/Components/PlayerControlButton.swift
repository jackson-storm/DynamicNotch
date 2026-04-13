//
//  PlayerControlButton.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct PlayerControlButton: View {
    @Environment(\.notchScale) var scale
    
    let systemImage: String
    let fontSize: CGFloat
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .buttonStyle(PressedButtonStyle(width: width, height: height))
    }
}
