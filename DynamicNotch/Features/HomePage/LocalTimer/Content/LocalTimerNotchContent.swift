import SwiftUI

struct LocalTimerNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Media.localTimer.id
    let localTimerViewModel: LocalTimerViewModel
    
    var priority: Int { NotchContentRegistry.Media.localTimer.priority }
    var isExpandable: Bool { true }
    
    var strokeColor: Color {
        .orange.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + minimalTimerSize, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight + 70)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 225, height: baseHeight + 50)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(LocalTimerMinimalNotchView(viewModel: localTimerViewModel))
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(LocalTimerExpandedNotchView(localTimerViewModel: localTimerViewModel))
    }
}

extension LocalTimerNotchContent {
    var minimalTimerSize: CGFloat {
        switch localTimerViewModel.formattedRemainingTime {
        case let value where value.contains("h"):
            return 170
        case let value where value.contains(":"):
            return 110
        default:
            return 170
        }
    }
}
