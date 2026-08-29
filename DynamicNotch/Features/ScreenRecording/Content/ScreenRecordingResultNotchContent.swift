import SwiftUI

struct ScreenRecordingResultNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.ScreenRecording.result.id
    let viewModel: ScreenRecordingResultViewModel

    var priority: Int { NotchContentRegistry.ScreenRecording.result.priority }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 160, height: baseHeight + 160)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 200, height: baseHeight + 160)
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 26, bottom: 40)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(ScreenRecordingResultNotchView(viewModel: viewModel))
    }
}
