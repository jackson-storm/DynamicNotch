//
//  CustomButton.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/20/26.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var width: CGFloat = .infinity
    var height: CGFloat = 30
    var backgroundColor: Color = .blue
    var foregroundColor: Color = .white
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: width, maxHeight: height)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(30)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
