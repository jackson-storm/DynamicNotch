import SwiftUI

enum LockScreenEvent: Equatable {
    case started
    case stopped
}

struct LockScreenNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.LockScreen.activity.id
    
    let lockScreenManager: LockScreenManager
    let style: LockScreenStyle

    var priority: Int { NotchContentRegistry.LockScreen.activity.priority }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch style {
        case .enlarged:
            .init(width: baseWidth + 150, height: baseHeight)
        case .compact:
            .init(width: baseWidth + 55, height: baseHeight)
        }
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch style {
        case .enlarged:
            .init(width: baseWidth + 120, height: baseHeight)
        case .compact:
            .init(width: baseWidth + 45, height: baseHeight)
        }
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(LockScreenNotchView(lockScreenManager: lockScreenManager, style: style))
    }
}
