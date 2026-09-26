//
//  TrayActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/26/26.
//

import SwiftUI

struct TrayActiveNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @ObservedObject var fileTrayViewModel: FileTrayViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "tray.full.fill")
                .font(.system(size: isNotchlessScreen ? 16 : 18, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(fileTrayViewModel.count)")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.leading, isNotchlessScreen ? 5.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 8.scaled(by: scale) : 14.scaled(by: scale))
    }
}
