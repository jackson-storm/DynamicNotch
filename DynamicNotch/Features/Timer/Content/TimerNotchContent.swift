import SwiftUI

struct TimerNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id: String
    let source: TimerSource
    let settingsViewModel: SettingsViewModel?

    var priority: Int { NotchContentRegistry.Media.timer.priority }
    
    var strokeColor: Color {
        if let settingsViewModel, settingsViewModel.isDefaultActivityStrokeEnabled {
            return .white.opacity(0.2)
        }
        return .orange.opacity(0.3)
    }

    var isExpandable: Bool { true }

    init(source: TimerSource, settingsViewModel: SettingsViewModel? = nil) {
        self.source = source
        self.settingsViewModel = settingsViewModel
        self.id = NotchContentRegistry.Media.timer.id
    }

    init(timerViewModel: TimerViewModel, settingsViewModel: SettingsViewModel) {
        self.source = .system(timerViewModel)
        self.settingsViewModel = settingsViewModel
        self.id = NotchContentRegistry.Media.timer.id
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + minimalTimerSize, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight + 60)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 60, height: baseHeight)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 225, height: baseHeight + 50)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(TimerMinimalNotchView(source: source))
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(TimerExpandedNotchView(source: source))
    }
}

extension TimerNotchContent {
    var minimalTimerSize: CGFloat {
        switch source.formattedTime(at: .now) {
        case let value where value.contains("h"):
            return 170
        case let value where value.contains(":"):
            return 110
        default:
            return 170
        }
    }
}
