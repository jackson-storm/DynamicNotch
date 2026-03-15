//
//  Untitled.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/3/26.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

struct AirDropNotchContent: NotchContentProtocol {
    let id = "airdrop"
    let airDropViewModel: AirDropNotchViewModel
    let notchViewModel: NotchViewModel
    
    var priority: Int { 90 }
    var strokeColor: Color { .blue.opacity(0.3) }
    var offsetXTransition: CGFloat { -20 }
    var offsetYTransition: CGFloat { -90 }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 40, height: baseHeight + 110)
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
                RoundedRectangle(cornerRadius: 18)
                    .fill(airDropViewModel.isDraggingFile ? .blue.opacity(0.2) : .clear.opacity(0))
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
