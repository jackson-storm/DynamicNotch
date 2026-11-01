import SwiftUI

/// The detached minimal presentation described in Apple's Live Activities HIG.
struct SecondaryLiveActivityView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @State private var hoverTask: Task<Void, Never>?

    var body: some View {
        if let content = notchViewModel.secondaryLiveActivity {
            let height = max(27, notchViewModel.notchModel.baseHeight)
            let width = content is TimerNotchContent ? max(42, height) : height
            Button { notchViewModel.expandLiveActivity(id: content.id) } label: {
                content.makeMinimalView()
                    .frame(width: width, height: height)
                    .background(.black, in: Capsule())
                    .overlay { Capsule().stroke(.white.opacity(0.12), lineWidth: 0.5) }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .id(content.id)
            .accessibilityIdentifier("notch.secondaryActivity")
            .onHover { hovering in
                hoverTask?.cancel()
                guard hovering else { return }
                hoverTask = Task {
                    try? await Task.sleep(for: .seconds(notchViewModel.notchHoverExpandDelay))
                    guard !Task.isCancelled, notchViewModel.secondaryLiveActivity?.id == content.id else { return }
                    notchViewModel.expandLiveActivity(id: content.id)
                }
            }
            .onDisappear { hoverTask?.cancel() }
            .offset(x: notchViewModel.presentedNotchSize.width / 2 + 7 + width / 2,
                    y: notchViewModel.isDynamicIsland ? 3 : 1)
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
        }
    }
}
