//
//  NavigationCardButtonStyle.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/14/26.
//

import SwiftUI

struct NavigationCardButtonStyle: ButtonStyle {
    let position: RowPosition
    
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape
                    .fill(configuration.isPressed ? (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)) : Color.clear)
            }
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var shape: UnevenRoundedRectangle {
        switch position {
        case .first:
            return UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16, style: .continuous)
        case .middle:
            return UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
        case .last:
            return UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0, style: .continuous)
        case .single:
            return UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 16, style: .continuous)
        }
    }
}
