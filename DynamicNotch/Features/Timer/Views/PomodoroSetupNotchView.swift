import SwiftUI

struct PomodoroSetupNotchView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    let notchViewModel: NotchViewModel
    let stopwatchViewModel: StopwatchViewModel?

    var body: some View {
        PomodoroPanelView(
            viewModel: viewModel,
            notchViewModel: notchViewModel,
            stopwatchViewModel: stopwatchViewModel
        )
    }
}
