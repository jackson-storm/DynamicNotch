//
//  NotchSizeNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/10/26.
//

import SwiftUI

enum NotchSizeEvent: Equatable {
    case width
    case height
}

struct NotchSizeWidthNotchContent: NotchContentProtocol {
    let id = "notchSize.width"
    
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { 60 }
    var strokeColor: Color { .red }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth, height: baseHeight + 40)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NotchSizeWidthNotchView(settingsViewModel: settingsViewModel))
    }
}

struct NotchSizeHeightNotchContent: NotchContentProtocol {
    let id = "notchSize.height"
    
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { 61 }
    var strokeColor: Color { .red }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NotchSizeHeightNotchView(settingsViewModel: settingsViewModel))
    }
}

private struct NotchSizeWidthNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                AnimatedLevelText(level: settingsViewModel.notchWidth, fontSize: 18)
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
        .font(.system(size: 18))
        .foregroundColor(.white)
        .padding(.horizontal, 14.scaled(by: scale))
        .padding(.bottom, 10.scaled(by: scale))
    }
}

private struct NotchSizeHeightNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "chevron.up.chevron.down")
            Spacer()
            AnimatedLevelText(level: settingsViewModel.notchHeight, fontSize: 18)
        }
        .font(.system(size: 18))
        .foregroundColor(.white)
        .padding(.horizontal, 16.scaled(by: scale))
    }
}
