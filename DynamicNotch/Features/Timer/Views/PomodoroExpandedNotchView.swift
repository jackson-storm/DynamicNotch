import SwiftUI

struct PomodoroExpandedNotchView: View {
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
            width: max(0, notchViewModel.presentedNotchSize.width),
            height: max(0, notchViewModel.presentedNotchSize.height),
            alignment: .top
        )
        .clipped()
    }
}
