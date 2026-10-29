import SwiftUI

struct ScreenshotNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Screenshot.active.id
    let viewModel: ScreenshotViewModel
    
    var priority: Int { NotchContentRegistry.Screenshot.active.priority }
    var allowsPressScaleEffect: Bool { false }
    
    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 160, height: baseHeight + 105)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 230, height: baseHeight + 100)
    }
    
    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 28, bottom: 40)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.3
    }
    
    @MainActor
    func compactView() -> AnyView {
        AnyView(ScreenshotNotchView(screenshotViewModel: viewModel))
    }
}
