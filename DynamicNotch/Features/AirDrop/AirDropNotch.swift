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
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        .blue.opacity(0.3)
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
            
            AirDropDropZoneView(isTargeted: isTargeted)
        }
        .padding(.horizontal, AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
    }
}

private struct AirDropDropZoneView: View {
    let isTargeted: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: AirDropDropZoneMetrics.cornerRadius)
            .fill(isTargeted ? .blue.opacity(0.2) : .clear.opacity(0))
            .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [20, 10]))
            .frame(height: AirDropDropZoneMetrics.height)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 22, weight: .semibold))
                    
                    Text(verbatim: "AirDrop")
                        .font(.system(size: 12))
                }
                .foregroundColor(.blue)
            }
    }
}
