//
//  LocalTimerSetupNotchContent.swift
//  DynamicNotch
//

import SwiftUI

struct LocalTimerSetupNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Media.localTimerSetup.id
    let localTimerViewModel: LocalTimerViewModel
    var onClose: (() -> Void)? = nil
    var priority: Int { NotchContentPriority.localTimerSetup }
    var allowsCompactPressScaleEffect: Bool = false

    var strokeColor: Color {
        .orange.opacity(0.3)
    }
    
    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 30, bottom: 45)
    }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 160, height: baseHeight + 135)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 220, height: baseHeight + 135)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.25
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel, onClose: onClose))
    }
}
