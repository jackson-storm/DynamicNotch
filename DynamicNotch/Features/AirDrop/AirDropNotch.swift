//
//  AirDropNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/24/26.
//

import SwiftUI

enum AirDropDropZoneMetrics {
    static let cornerRadius: CGFloat = 18
    static let height: CGFloat = 90
    static let horizontalPadding: CGFloat = 40
    static let verticalPadding: CGFloat = 16
}

struct AirDropNotchContent: NotchContentProtocol {
    let id = "airdrop"
    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { 90 }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.mediaAndFiles.isAirDropDefaultStrokeEnabled ?
        .white.opacity(0.2) :
        Color.accentColor.opacity(0.3)
    }
    var offsetXTransition: CGFloat { -20 }
    var offsetYTransition: CGFloat { -90 }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 40, height: baseHeight + 110)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(AirDropNotchView(airDropViewModel: airDropViewModel))
    }
}

struct AirDropNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    
    var body: some View {
        AirDropDropZoneContainerView(isTargeted: airDropViewModel.isDropZoneTargeted)
    }
}

struct AirDropPreviewNotchView: View {
    var body: some View {
        AirDropDropZoneContainerView(isTargeted: true)
    }
}

private struct AirDropDropZoneContainerView: View {
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
