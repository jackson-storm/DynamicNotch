//
//  TrayActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/26/26.
//

import SwiftUI

struct TrayActiveNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var fileTrayViewModel: FileTrayViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "document.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(fileTrayViewModel.count)")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.gradient)
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
