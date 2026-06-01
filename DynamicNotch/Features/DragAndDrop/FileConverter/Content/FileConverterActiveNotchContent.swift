//
//  FileConverterActiveNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import SwiftUI

struct FileConverterActiveNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.DragAndDrop.fileConverterActive.id
    let fileConverterViewModel: FileConverterViewModel
    let mediaSettings: MediaAndFilesSettingsStore
    let onRequestCollapse: @MainActor () -> Void

    var priority: Int { NotchContentRegistry.DragAndDrop.fileConverterActive.priority }
    var isExpandable: Bool { true }

    var windowLink: (@MainActor () -> Void)? {
        guard fileConverterViewModel.isConverted else { return nil }

        return {
            fileConverterViewModel.revealConvertedFile()
        }
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 65, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 150, height: baseHeight + 165)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 30, bottom: 40)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 55, height: baseHeight)
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight + 165)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
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
