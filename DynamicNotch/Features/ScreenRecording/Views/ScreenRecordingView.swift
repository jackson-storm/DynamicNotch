//
//  ScreenRecordingView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/30/26.
//

import SwiftUI

struct ScreenRecordingView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @State private var isBlinking = false

    var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .opacity(isBlinking ? 0.5 : 1)

            Spacer()
        }
        .padding(.vertical, isDynamicIsland ? 0 : 10)
        .padding(.horizontal, isDynamicIsland ? 10.scaled(by: scale) : 16.scaled(by: scale))
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
