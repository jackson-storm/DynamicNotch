//
//  HotspotActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct HotspotActiveNotchView: View {
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
