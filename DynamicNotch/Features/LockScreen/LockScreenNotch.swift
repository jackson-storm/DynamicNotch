import SwiftUI

enum LockScreenEvent: Equatable {
    case started
    case stopped
}

struct LockScreenNotchContent: NotchContentProtocol {
    let id = "lockScreen"
    let lockScreenManager: LockScreenManager

    var priority: Int { 92 }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 60, height: baseHeight)
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
            Image(systemName: lockScreenManager.isLocked ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
