import SwiftUI

enum LockScreenEvent: Equatable {
    case started
    case stopped
}

struct LockScreenNotchContent: NotchContentProtocol {
    static let contentID = "lockScreen"
    
    let id = Self.contentID
    let lockScreenManager: LockScreenManager

    var priority: Int { 92 }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 55, height: baseHeight)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(LockScreenNotchView(lockScreenManager: lockScreenManager))
    }
}

struct LockScreenNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var lockScreenManager: LockScreenManager

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: lockScreenManager.isShowingLockPresentation ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, 16.scaled(by: scale))
    }
}
