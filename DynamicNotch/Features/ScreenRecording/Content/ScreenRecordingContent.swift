import SwiftUI

enum ScreenRecordingEvent: Equatable {
    case started
    case stopped
}

struct ScreenRecordingContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.ScreenRecording.active.id
    let screenRecordingViewModel: ScreenRecordingViewModel
    let style: ScreenRecordingStyle

    init(
        screenRecordingViewModel: ScreenRecordingViewModel,
        style: ScreenRecordingStyle = .detailed
    ) {
        self.screenRecordingViewModel = screenRecordingViewModel
        self.style = style
    }

    @MainActor
    init(settingsViewModel: SettingsViewModel) {
        self.screenRecordingViewModel = ScreenRecordingViewModel(monitor: InactiveScreenRecordingMonitor())
        self.style = settingsViewModel.screenRecording.screenRecordingStyle
    }

    @MainActor
    init(screenRecordingViewModel: ScreenRecordingViewModel, settingsViewModel: SettingsViewModel) {
        self.screenRecordingViewModel = screenRecordingViewModel
        self.style = settingsViewModel.screenRecording.screenRecordingStyle
    }

    var priority: Int { NotchContentRegistry.ScreenRecording.active.priority }
    var isExpandable: Bool { true }
    var strokeColor: Color { .red.opacity(0.3) }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch style {
        case .compact:
            return .init(width: baseWidth + 60, height: baseHeight)
        case .detailed:
            return .init(width: baseWidth + 115, height: baseHeight)
        }
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch style {
        case .compact:
            return .init(width: baseWidth + 50, height: baseHeight)
        case .detailed:
            return .init(width: baseWidth + 105, height: baseHeight)
        }
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 130, height: baseHeight + 60)
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 210, height: baseHeight + 50)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 42)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        return baseHeight * 0.5
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(ScreenRecordingView(style: style, viewModel: screenRecordingViewModel))
    }

    @MainActor
    func expandedView() -> AnyView {
        AnyView(ScreenRecordingExpandedNotchView(viewModel: screenRecordingViewModel))
    }
}
