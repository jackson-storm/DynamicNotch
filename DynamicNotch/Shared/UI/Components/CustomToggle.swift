//
//  CustomToggle.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/8/26.
//

import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        ToggleBody(configuration: configuration)
    }
    
    private struct ToggleBody: View {
        @GestureState private var isPressed = false
        let configuration: Configuration
    
        var body: some View {
            HStack {
                configuration.label
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(configuration.isOn ? .blue : .gray.opacity(0.3))
                        .frame(width: 40, height: 22)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .scaleEffect(isPressed ? 0.8 : 1.0)
                        .shadow(radius: isPressed ? 3 : 1)
                        .offset(x: configuration.isOn ? 9 : -9)
                        .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isPressed) { _, pressed, _ in
                            pressed = true
                        }
                        .onEnded { _ in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                configuration.isOn.toggle()
                            }
                        }
                )
            }
            .frame(maxWidth: .infinity)
        }
    }
}
