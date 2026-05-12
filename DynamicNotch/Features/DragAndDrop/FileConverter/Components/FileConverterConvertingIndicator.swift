//
//  FileConverterConvertingIndicator.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/12/26.
//

import SwiftUI

struct FileConverterConvertingIndicator: View {
    @State private var isRotating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2.5)

            Circle()
                .trim(from: 0.12, to: 0.78)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(isRotating ? 360 : 0))
        }
        .animation(
            .linear(duration: 1.2).repeatForever(autoreverses: false),
            value: isRotating
        )
        .onAppear {
            isRotating = true
        }
        .onDisappear {
            isRotating = false
        }
    }
}
