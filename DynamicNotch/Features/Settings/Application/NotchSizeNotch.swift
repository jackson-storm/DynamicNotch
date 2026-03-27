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
    let generalSettingsViewModel: GeneralSettingsViewModel
    
    var priority: Int { 60 }
    var strokeColor: Color { .red }
    var offsetYTransition: CGFloat { -60 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth, height: baseHeight + 40)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NotchSizeWidthNotchView(generalSettingsViewModel: generalSettingsViewModel))
    }
}

struct NotchSizeHeightNotchContent: NotchContentProtocol {
    let id = "notchSize.height"
    let generalSettingsViewModel: GeneralSettingsViewModel
    
    var priority: Int { 61 }
    var strokeColor: Color { .red }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NotchSizeHeightNotchView(generalSettingsViewModel: generalSettingsViewModel))
    }
}

private struct NotchSizeWidthNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                Text(generalSettingsViewModel.notchWidth.description)
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
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "chevron.up.chevron.down")
            Spacer()
            Text(generalSettingsViewModel.notchHeight.description)
        }
        .font(.system(size: 18))
        .foregroundColor(.white)
        .padding(.horizontal, 16.scaled(by: scale))
    }
}
