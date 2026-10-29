//
//  FaceIDNotchContent.swift
//  DynamicNotch
//

import SwiftUI

struct FaceIDNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id: String = NotchContentRegistry.FaceID.scanning.id
    var priority: Int { NotchContentPriority.faceID }

    let service: FaceIDService
    var style: FaceIDPresentationStyle = .expanded

    var strokeColor: Color {
        if service.state.isSuccess {
            return .green.opacity(0.3)
        } else if service.state.isFailed {
            return .red.opacity(0.3)
        } else {
            return .white.opacity(0.2)
        }
    }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        CGSize(width: baseWidth + 40, height: baseHeight + 125)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        CGSize(width: baseWidth + 70, height: baseHeight + 120)
    }

    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 44)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.25
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(
            FaceIDNotchView(style: style, service: service)
        )
    }
}
