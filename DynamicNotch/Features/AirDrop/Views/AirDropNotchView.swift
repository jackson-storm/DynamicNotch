//
//  AirDropDropZoneView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct AirDropNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    
    var body: some View {
        AirDropDropZoneView(isTargeted: airDropViewModel.isDropZoneTargeted)
    }
}

private struct AirDropDropZoneView: View {
    let isTargeted: Bool

    var body: some View {
        VStack {
            Spacer()
            
            RoundedRectangle(cornerRadius: AirDropDropZoneMetrics.cornerRadius)
                .fill(isTargeted ? Color.accentColor.opacity(0.2) : .clear.opacity(0))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [20, 10]))
                .frame(height: AirDropDropZoneMetrics.height)
                .overlay {
                    VStack(spacing: 4) {
                        Image("airdrop.white")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 28, height: 28)
                        
                        Text(verbatim: "AirDrop")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color.accentColor)
                }
        }
        .padding(.horizontal, AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
    }
}
