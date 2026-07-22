import SwiftUI

enum ScreenRecordingEvent: Equatable {
    case started
    case stopped
}

struct ScreenRecordingContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.ScreenRecording.active.id
    let screenRecordingViewModel: ScreenRecordingViewModel
    let usesDefaultStroke: Bool

    init(screenRecordingViewModel: ScreenRecordingViewModel, usesDefaultStroke: Bool = false) {
        self.screenRecordingViewModel = screenRecordingViewModel
        self.usesDefaultStroke = usesDefaultStroke
    }

    @MainActor
    init(settingsViewModel: SettingsViewModel) {
        self.screenRecordingViewModel = ScreenRecordingViewModel(monitor: InactiveScreenRecordingMonitor())
        self.usesDefaultStroke = settingsViewModel.isDefaultActivityStrokeEnabled
    }

    @MainActor
    init(screenRecordingViewModel: ScreenRecordingViewModel, settingsViewModel: SettingsViewModel) {
        self.screenRecordingViewModel = screenRecordingViewModel
        self.usesDefaultStroke = settingsViewModel.isDefaultActivityStrokeEnabled
    }

    var priority: Int { NotchContentRegistry.ScreenRecording.active.priority }
    var isExpandable: Bool { true }
    var strokeColor: Color { usesDefaultStroke ? .white.opacity(0.2) : .red.opacity(0.3) }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 60, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 130, height: baseHeight + 60)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 20, bottom: 38)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 30, height: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 160, height: baseHeight + 50)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        return baseHeight * 0.5
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(ScreenRecordingView())
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(ScreenRecordingExpandedNotchView(viewModel: screenRecordingViewModel))
    }
}
