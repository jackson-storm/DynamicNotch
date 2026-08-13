//
//  FocusOnExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 8/13/26.
//

internal import AppKit
import SwiftUI

struct FocusOnExpandedNotchView: View {
    let focusModeType: FocusModeType
    
    @ObservedObject private var manager = DoNotDisturbManager.shared
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(activeFocusModeType.tint.opacity(0.2))
                        .frame(width: 42, height: 42)

                    Image(systemName: activeFocusModeType.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(activeFocusModeType.tint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(titleText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)

                    Text(verbatim: "Focus On")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(activeFocusModeType.tint)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding(.horizontal, isDynamicIsland ? 25 : 40)
        .padding(.bottom, isDynamicIsland ? 15 : 20)
    }
    
    private var activeFocusModeType: FocusModeType {
        if manager.isDoNotDisturbActive {
            return FocusModeType.resolve(
                identifier: manager.currentFocusModeIdentifier,
                name: manager.currentFocusModeName
            )
        }
        return focusModeType
    }

    private var titleText: String {
        let modeName = manager.currentFocusModeName
        if !modeName.isEmpty {
            return modeName
        }
        return activeFocusModeType.displayName
    }
}
