//
//  HotspotNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/27/26.
//

import SwiftUI

struct HotspotActiveContent: NotchContentProtocol {
    let id = "hotspot.active"
    
    var strokeColor: Color { .green.opacity(0.3) }
    
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
