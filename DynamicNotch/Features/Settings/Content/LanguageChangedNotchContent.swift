//
//  LanguageChangedNotchContent.swift
//  DynamicNotch
//

import SwiftUI

struct LanguageChangedNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Settings.language.id
    var priority: Int { NotchContentRegistry.Settings.language.priority }
    
    let language: DynamicNotchLanguage
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 140, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 120, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(LanguageChangedNotchView(language: language))
    }
}
