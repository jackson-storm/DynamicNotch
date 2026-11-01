import SwiftUI

struct ToolHomePageNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let page: HomePages
    let id = NotchContentRegistry.HomePage.active.id
    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let height: CGFloat
        switch page {
        case .calculator: height = 300
        case .sound: height = 165
        default: height = 145
        }
        return .init(width: max(340, baseWidth + 160), height: baseHeight + height)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) { (24, 34) }
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat { 24 }

    @MainActor
    func makeView() -> AnyView { AnyView(EmptyView()) }
}
