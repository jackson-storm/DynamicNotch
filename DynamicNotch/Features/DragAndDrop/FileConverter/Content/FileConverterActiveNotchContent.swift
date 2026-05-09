//
//  FileConverterActiveNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import SwiftUI

struct FileConverterActiveNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.DragAndDrop.fileConverterActive.id

    let fileConverterViewModel: FileConverterViewModel
    let mediaSettings: MediaAndFilesSettingsStore
    let onRequestCollapse: @MainActor () -> Void

    var priority: Int { NotchContentRegistry.DragAndDrop.fileConverterActive.priority }
    var isExpandable: Bool { true }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 150, height: baseHeight + 150)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 30, bottom: 40)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            FileConverterActiveNotchView(
                fileConverterViewModel: fileConverterViewModel,
                mediaSettings: mediaSettings
            )
        )
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            FileConverterExpandedActiveNotchView(
                fileConverterViewModel: fileConverterViewModel,
                mediaSettings: mediaSettings,
                onRequestCollapse: onRequestCollapse
            )
        )
    }
}
