import SwiftUI

struct PomodoroSetupNotchView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    let notchViewModel: NotchViewModel
    let stopwatchViewModel: StopwatchViewModel?

    var body: some View {
        GeometryReader { geometry in
            PomodoroPanelView(
                viewModel: viewModel,
                notchViewModel: notchViewModel,
                stopwatchViewModel: stopwatchViewModel
            )
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .top
            )
        }
        .clipped()
    }
}
