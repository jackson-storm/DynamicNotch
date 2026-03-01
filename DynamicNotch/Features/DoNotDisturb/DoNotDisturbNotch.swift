//
//  Do.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import SwiftUI

struct DoNotDisturbOnNotchContent: NotchContentProtocol {
    let id = "doNotDisturb.on"
    
    var strokeColor: Color { .indigo.opacity(0.3) }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(DoNotDisturbOnNotchView())
    }
}

struct DoNotDisturbOffNotchContent: NotchContentProtocol {
    let id = "doNotDisturb.off"
    
    var strokeColor: Color { .gray.opacity(0.3) }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(DoNotDisturbOffNotchView())
    }
}

private struct DoNotDisturbOnNotchView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack {
            Image(systemName: "moon.fill")
                .font(.system(size: 16, weight: .bold))
            
            Spacer()
            
            Text("On")
        }
        .foregroundStyle(.indigo)
        .padding(.horizontal, 14.scaled(by: scale))
    }
}

private struct DoNotDisturbOffNotchView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack {
            Image(systemName: "moon.fill")
                .font(.system(size: 16, weight: .bold))
            
            Spacer()
            
            Text("Off")
        }
        .foregroundStyle(.gray.opacity(0.6))
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
