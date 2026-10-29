//
//  FaceIDEnrollmentNotchContent.swift
//  DynamicNotch
//

import SwiftUI

enum FaceIDEnrollmentStep: Equatable {
    case intro
    case camera
    case success

    func notchSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch self {
        case .intro:
            return CGSize(width: baseWidth + 160, height: baseHeight + 115)
        case .camera:
            return CGSize(width: baseWidth + 120, height: baseHeight + 240)
        case .success:
            return CGSize(width: baseWidth + 140, height: baseHeight + 75)
        }
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch self {
        case .intro:
            return CGSize(width: baseWidth + 250, height: baseHeight + 115)
        case .camera:
            return CGSize(width: baseWidth + 200, height: baseHeight + 240)
        case .success:
            return CGSize(width: baseWidth + 230, height: baseHeight + 75)
        }
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        switch self {
        case .intro:
            baseHeight * 0.25
        case .camera:
            baseHeight * 0.2
        case .success:
            baseHeight * 0.5
        }
    }
}

struct FaceIDEnrollmentNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    var id: String { "\(NotchContentRegistry.FaceID.enrollment.id).\(step)" }
    var priority: Int { NotchContentRegistry.FaceID.enrollment.priority }

    let step: FaceIDEnrollmentStep
    let settings: FaceIDSettingsStore
    let notchViewModel: NotchViewModel
    let cameraService: FaceIDEnrollmentCameraService

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        step.notchSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        step.dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 44)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        step.dynamicIslandCornerRadius(baseHeight: baseHeight)
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(
            FaceIDEnrollmentNotchView(
                step: step,
                notchViewModel: notchViewModel,
                settings: settings,
                cameraService: cameraService
            )
        )
    }
}
