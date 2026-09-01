internal import AppKit
import Combine
import SwiftUI

@MainActor
final class NotchTimerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let timerViewModel: TimerViewModel
    private let settingsViewModel: SettingsViewModel
    private let localTimerViewModel: LocalTimerViewModel
    private var cancellables = Set<AnyCancellable>()

    init(
        notchViewModel: NotchViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel,
        localTimerViewModel: LocalTimerViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.timerViewModel = timerViewModel
        self.settingsViewModel = settingsViewModel
        self.localTimerViewModel = localTimerViewModel

        setupWorkspaceObservation()
    }

    private func setupWorkspaceObservation() {
        NSWorkspace.shared.publisher(for: \.frontmostApplication)
            .sink { [weak self] _ in
                guard let self else { return }
                self.handleFrontmostApplicationChange()
            }
            .store(in: &cancellables)
    }

    func handleFrontmostApplicationChange() {
        guard settingsViewModel.isLiveActivityEnabled(.timer),
              timerViewModel.snapshot != nil else {
            return
        }

        if localTimerViewModel.state == .running || localTimerViewModel.state == .paused {
            return
        }

        if settingsViewModel.application.isCloseAtFocusLiveActivityEnabled,
           let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier == "com.apple.clock" {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
        } else {
            handleTimer(.updated)
        }
    }

    func handleTimer(_ event: TimerEvent) {
        switch event {
        case .started, .updated:
            if localTimerViewModel.state == .running || localTimerViewModel.state == .paused {
                return
            }
            guard settingsViewModel.isLiveActivityEnabled(.timer) else {
                notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
                return
            }
            guard timerViewModel.snapshot != nil else { return }

            if settingsViewModel.application.isCloseAtFocusLiveActivityEnabled,
               let app = NSWorkspace.shared.frontmostApplication,
               app.bundleIdentifier == "com.apple.clock" {
                notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
                return
            }

            notchViewModel.send(
                .showLiveActivity(
                    TimerNotchContent(
                        source: .system(timerViewModel),
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
        }
    }
}

