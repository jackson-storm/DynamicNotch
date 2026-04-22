import SwiftUI

struct TimerNotchContent: NotchContentProtocol {
    static let activityID = "clock.timer"

    let id = Self.activityID
    let timerViewModel: TimerViewModel
    let settingsViewModel: SettingsViewModel

    var priority: Int { 86 }
    var isExpandable: Bool { true }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.mediaAndFiles.isTimerDefaultStrokeEnabled ?
        .white.opacity(0.2) :
        .orange.opacity(0.3)
    }
    
    var offsetXTransition: CGFloat { -90 }
    var expandedOffsetXTransition: CGFloat { -90 }
    var expandedOffsetYTransition: CGFloat { -60 }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + minimalTimerSize, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight + 70)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(TimerMinimalNotchView(timerViewModel: timerViewModel))
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(TimerExpandedNotchView(timerViewModel: timerViewModel))
    }
}

extension TimerNotchContent {
    var minimalTimerSize: CGFloat {
        switch timerViewModel.formattedTime {
        case let value where value.contains("h"):
            170
        case let value where value.contains(":"):
            110
        default:
            170
        }
    }
}
