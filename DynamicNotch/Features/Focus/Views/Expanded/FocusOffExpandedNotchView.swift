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
    
    @ObservedObject private var manager: DoNotDisturbManager
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    init(
        focusModeType: FocusModeType,
        manager: DoNotDisturbManager = .shared
    ) {
        self.focusModeType = focusModeType
        self._manager = ObservedObject(wrappedValue: manager)
    }

    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(activeFocusModeType.tint.opacity(0.25))
                        .frame(width: 45, height: 45)
                    
                    Image(systemName: focusModeType.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                Text(titleText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer()
                
                Text(verbatim: "Off")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
                    .lineLimit(1)
                    .padding(.trailing, 5)
            }
        }
        .padding(.horizontal, isDynamicIsland ? 15 : 40)
        .padding(.bottom, isDynamicIsland ? 15 : 15)
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
        focusModeType.displayName
    }
}
