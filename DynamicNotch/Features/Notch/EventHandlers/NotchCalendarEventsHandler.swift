import SwiftUI
import Combine

@MainActor
final class NotchCalendarEventsHandler {
    private let notchViewModel: NotchViewModel
    private let calendarViewModel: CalendarViewModel
    private let settingsViewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    init(
        notchViewModel: NotchViewModel,
        calendarViewModel: CalendarViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.calendarViewModel = calendarViewModel
        self.settingsViewModel = settingsViewModel

        setupWorkspaceObservation()
    }

    private func setupWorkspaceObservation() {
        NSWorkspace.shared.publisher(for: \.frontmostApplication)
            .sink { [weak self] app in
                guard let self else { return }
                self.handleCalendarEvent(self.calendarViewModel.hasUpcomingEvent)
            }
            .store(in: &cancellables)
    }

    func handleCalendarEvent(_ hasUpcoming: Bool) {
        guard hasUpcoming && settingsViewModel.calendar.isCalendarLiveActivityEnabled else {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.calendar.id))
            return
        }

        if settingsViewModel.application.isCloseAtFocusLiveActivityEnabled {
            if let app = NSWorkspace.shared.frontmostApplication,
               app.bundleIdentifier == "com.apple.iCal" {
                notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.calendar.id))
                return
            }
        }

        notchViewModel.send(
            .showLiveActivity(
                CalendarNotchContent(
                    calendarViewModel: calendarViewModel,
                    notchViewModel: notchViewModel
                )
            )
        )
    }
}
