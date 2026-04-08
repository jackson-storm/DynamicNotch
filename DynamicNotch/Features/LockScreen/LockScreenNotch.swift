import SwiftUI

enum LockScreenEvent: Equatable {
    case started
    case stopped
}

struct LockScreenNotchContent: NotchContentProtocol {
    static let contentID = "lockScreen"
    
    let id = Self.contentID
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

struct LockScreenNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var lockScreenManager: LockScreenManager
    let style: LockScreenStyle

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: lockScreenManager.isShowingLockPresentation ? "lock.fill" : "lock.open.fill")
                .font(.system(size: style == .enlarged ? 16 : 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()

            if style == .enlarged {
                Text(statusTitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, horizontalPadding.scaled(by: scale))
    }

    private var statusTitle: String {
        lockScreenManager.isShowingLockPresentation ? "Locked" : "Unlocked"
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .enlarged:
            18
        case .compact:
            16
        }
    }
}
