//
//  ScreenRecordingView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/30/26.
//

import SwiftUI

struct ScreenRecordingView: View {
    @Environment(\.notchScale) private var scale
    @State private var isBlinking = false

    var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .opacity(isBlinking ? 0.5 : 1)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16.scaled(by: scale))
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                isBlinking = true
            }
        }
        .onDisappear {
            isBlinking = false
        }
    }
}
