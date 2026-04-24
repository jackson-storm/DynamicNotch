import SwiftUI

enum LockScreenEvent: Equatable {
    case started
    case stopped
}

struct LockScreenNotchContent: NotchContentProtocol {
    let id = "lockScreen"
    
    let lockScreenManager: LockScreenManager
    let style: LockScreenStyle

    var priority: Int { 92 }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch style {
        case .enlarged:
                .init(width: baseWidth + (lockScreenManager.isShowingLockPresentation ? 120 : 150), height: baseHeight)
        case .compact:
            .init(width: baseWidth + 55, height: baseHeight)
        }
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(LockScreenNotchView(lockScreenManager: lockScreenManager, style: style))
    }
}
