//
//  Untitled.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/3/26.
//

import SwiftUI
internal import UniformTypeIdentifiers

func shareViaAirDrop(urls: [URL], point: NSPoint, view: NSView) {
    let sharingService = NSSharingService(named: .sendViaAirDrop)
    sharingService?.delegate = nil
    sharingService?.perform(withItems: urls)
}

struct AirDropNotchContent: NotchContentProtocol {
    let id = "airdrop"
    let airDropViewModel: AirDropNotchViewModel
    let notchViewModel: NotchViewModel
    
    var strokeColor: Color { .blue.opacity(0.3) }
    var offsetYTransition: CGFloat { -80 }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight + 110)
    }
    
    func makeView() -> AnyView {
        AnyView(AirDropNotchView(airDropViewModel: airDropViewModel, notchViewModel: notchViewModel))
    }
}

struct AirDropNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @ObservedObject var notchViewModel: NotchViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue.opacity(0.15))
                    .stroke(.blue,style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [20, 10]))
                    .frame(height: 90)
                    .overlay{
                        VStack(spacing: 8) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 22, weight: .semibold))
                            
                            Text("AirDrop")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.blue)
                    }
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
    }
}
