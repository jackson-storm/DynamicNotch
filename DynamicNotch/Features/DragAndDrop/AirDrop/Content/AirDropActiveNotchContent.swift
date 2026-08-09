//
//  AirDropActiveNotchContent.swift
//  DynamicNotch
//

import SwiftUI

struct AirDropActiveNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.DragAndDrop.airDropTransferActive.id
    let airDropViewModel: AirDropNotchViewModel
    let mediaSettings: MediaAndFilesSettingsStore

    var priority: Int { NotchContentRegistry.DragAndDrop.airDropTransferActive.priority }
    var isExpandable: Bool { true }

    var strokeColor: Color {
        Color.blue.opacity(0.3)
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 120, height: baseHeight + 70)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 36)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 45, height: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 150, height: baseHeight + 70)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.3
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            AirDropActiveNotchView(
                airDropViewModel: airDropViewModel
            )
        )
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            AirDropExpandedActiveNotchView(
                airDropViewModel: airDropViewModel
            )
        )
    }
}
