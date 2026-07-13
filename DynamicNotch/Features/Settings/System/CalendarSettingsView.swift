import SwiftUI
internal import EventKit

struct CalendarSettingsView: View {
    @ObservedObject var settings: CalendarSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            calendarActivity
        }
    }

    private var calendarActivity: some View {
        SettingsCard(title: "settings.activities.calendar.title") {
            SettingsToggleRow(
                title: "settings.activities.calendar.liveActivity",
                description: "settings.activities.calendar.liveActivity.desc",
                systemImage: "calendar",
                color: .blue,
                isOn: $settings.isCalendarLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.calendar"
            )


        }
    }
}
