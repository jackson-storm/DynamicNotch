//
//  SettingsIconBadge.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsIconBadge: View {
    let systemImage: String
    let tint: Color
    let size: CGFloat
    let iconSize: CGFloat
    let cornerRadius: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(tint.gradient)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            }
    }
}
