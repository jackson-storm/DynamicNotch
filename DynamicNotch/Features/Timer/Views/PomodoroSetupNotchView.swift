import SwiftUI

struct PomodoroSetupNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var viewModel: PomodoroViewModel
    @ObservedObject var notchViewModel: NotchViewModel
    let stopwatchViewModel: StopwatchViewModel?

    var body: some View {
        PomodoroPanelView(
            viewModel: viewModel,
            notchViewModel: notchViewModel,
            stopwatchViewModel: stopwatchViewModel
        )
        .frame(
            width: max(0, notchViewModel.presentedNotchSize.width - homePageHorizontalInsets),
            height: max(0, notchViewModel.presentedNotchSize.height - 10),
            alignment: .top
        )
        .clipped()
    }

    private var homePageHorizontalInsets: CGFloat {
        isDynamicIsland ? 16 : 66
    }
}
