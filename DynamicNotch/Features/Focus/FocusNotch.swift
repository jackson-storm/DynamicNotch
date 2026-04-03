//
//  Do.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import SwiftUI

struct FocusOnNotchContent: NotchContentProtocol {
    let id = "focus.on"
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { 60 }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        .indigo.opacity(0.3)
    }
    
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(FocusOnNotchView())
    }
}

struct FocusOffNotchContent: NotchContentProtocol {
    let id = "focus.off"
    let settingsViewModel: SettingsViewModel
    
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        .gray.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(FocusOffNotchView())
    }
}

private struct FocusOnNotchView: View {
    var body: some View { FocusStatusNotchView(title: "On", tint: .indigo) }
}

private struct FocusOffNotchView: View {
    var body: some View { FocusStatusNotchView(title: "Off", tint: .gray.opacity(0.6)) }
}

struct FocusPreviewNotchView: View {
    var body: some View { FocusOnNotchView() }
}

private struct FocusStatusNotchView: View {
    @Environment(\.notchScale) var scale

    let title: LocalizedStringKey
    let tint: Color

    var body: some View {
        HStack {
            Image(systemName: "moon.fill")
                .font(.system(size: 16, weight: .bold))
            
            Spacer()
            
            Text(title)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
