//
//  HotspotNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/27/26.
//

import SwiftUI

struct HotspotActiveContent: NotchContentProtocol {
    let id = "hotspot.active"
    let generalSettingsViewModel: GeneralSettingsViewModel
    
    var priority: Int { 70 }
    var strokeColor: Color {
        generalSettingsViewModel.isHotspotDefaultStrokeEnabled ?
        .white.opacity(0.2) :
        .green.opacity(0.3)
    }
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 80, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HotspotActiveNotchView())
    }
}

private struct HotspotActiveNotchView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack {
            Image(systemName: "personalhotspot")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
            
            Spacer()
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}

struct HotspotPreviewNotchView: View {
    var body: some View {
        HotspotActiveNotchView()
    }
}
