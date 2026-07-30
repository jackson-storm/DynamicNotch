//
//  HotspotActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct HotspotActiveNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    let style: HotspotAppearanceStyle
    
    var body: some View {
        HStack {
            switch style {
            case .minimal:
                minimal
                
            case .detailed:
                detailed
            }
        }
        .padding(.leading, isDynamicIsland ? 4.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 6.scaled(by: scale) : 14.scaled(by: scale))
    }
    
    private var minimal: some View {
        HStack {
            Image(systemName: "personalhotspot")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
            
            Spacer()
        }
    }
    
    private var detailed: some View {
        HStack {
            Image(systemName: "personalhotspot")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
            
            Spacer()
            
            Text(verbatim: "On")
                .font(.system(size: 14))
                .foregroundStyle(.green.opacity(0.8))
        }
    }
}
