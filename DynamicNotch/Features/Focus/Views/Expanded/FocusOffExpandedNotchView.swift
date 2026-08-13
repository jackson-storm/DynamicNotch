//
//  FocusOffExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 8/13/26.
//

internal import AppKit
import SwiftUI

struct FocusOffExpandedNotchView: View {
    let focusModeType: FocusModeType
    
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 42, height: 42)

                    Image(systemName: focusModeType.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(titleText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)

                    Text(verbatim: "Focus Off")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding(.horizontal, isDynamicIsland ? 25 : 40)
        .padding(.bottom, isDynamicIsland ? 15 : 20)
    }
    
    private var titleText: String {
        focusModeType.displayName
    }
}
