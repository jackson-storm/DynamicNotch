//
//  HotspotNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/27/26.
//

import SwiftUI

struct HotspotActiveContent: NotchContentProtocol {
    let id = "hotspot.active"
    let settingsViewModel: SettingsViewModel
    
    private var appearanceStyle: HotspotAppearanceStyle {
        settingsViewModel.connectivity.hotspotAppearanceStyle
    }
    
    var priority: Int { 70 }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.connectivity.isHotspotDefaultStrokeEnabled ?
            .white.opacity(0.2) :
            .green.opacity(0.3)
    }
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width = appearanceStyle == .minimal ? 80 : 80
        return .init(width: baseWidth + CGFloat(width), height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HotspotActiveNotchView(style: appearanceStyle))
    }
}

private struct HotspotActiveNotchView: View {
    @Environment(\.notchScale) var scale
    let style: HotspotAppearanceStyle
    
    var body: some View {
        HStack(spacing: 0) {
            if style == .minimal {
                Image(systemName: "personalhotspot")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.green)
                
                Spacer()
                
            } else {
                Image(systemName: "personalhotspot")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.green)
                
                Spacer(minLength: 10)
                
                Text(verbatim: "On")
                    .font(.system(size: 14))
                    .foregroundStyle(.green.opacity(0.8))
            }
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}

struct HotspotPreviewNotchView: View {
    var body: some View {
        HotspotActiveNotchView(style: .minimal)
    }
}
