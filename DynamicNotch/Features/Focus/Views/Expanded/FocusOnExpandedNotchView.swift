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
                        .fill(.white)
                        .frame(width: 45, height: 45)
                    
                    Image(systemName: activeFocusModeType.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(activeFocusModeType.tint)
                }
                
                Text(titleText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer()
                
                Text(verbatim: "On")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(activeFocusModeType.tint)
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
        let modeName = manager.currentFocusModeName
        if !modeName.isEmpty {
            return modeName
        }
        return activeFocusModeType.displayName
    }
}
