//
//  TrayActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/26/26.
//

import SwiftUI

struct TrayActiveNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var fileTrayViewModel: FileTrayViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "tray.full.fill")
                .font(.system(size: isDynamicIsland ? 16 : 18, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(fileTrayViewModel.count)")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.gradient)
        }
        .padding(.horizontal, isDynamicIsland ? 8.scaled(by: scale) : 14.scaled(by: scale))
    }
}
