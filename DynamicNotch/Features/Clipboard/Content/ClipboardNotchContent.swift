import SwiftUI

struct ClipboardNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Clipboard.recent.id
    let item: ClipboardHistoryItem
    let viewModel: ClipboardHistoryViewModel
    let notchViewModel: NotchViewModel

    var isExpandable: Bool { true }
    var strokeColor: Color { ClipboardDesign.accent.opacity(0.28) }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 72, height: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 50, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 260, height: baseHeight + 230)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 280, height: baseHeight + 230)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 30, bottom: 38)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.28
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(ClipboardCompactNotchView(item: item))
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            ClipboardHistoryNotchView(
                viewModel: viewModel,
                topClearance: max(0, notchViewModel.notchModel.baseHeight),
                appliesOuterPadding: true,
                onItemRestored: { [weak notchViewModel] in
                    notchViewModel?.hideTemporaryNotification()
                }
            )
        )
    }
}
