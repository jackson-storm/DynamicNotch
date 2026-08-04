import SwiftUI
internal import EventKit

struct CalendarSettingsView: View {
    @ObservedObject var settings: CalendarSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            calendarActivityCard
            displayOptionsCard
            privacyAndSoundCard
        }
    }

    private var calendarActivityCard: some View {
        SettingsCard(title: "settings.activities.calendar.title") {
            SettingsToggleRow(
                title: "settings.activities.calendar.liveActivity",
                description: "settings.activities.calendar.liveActivity.desc",
                systemImage: "29.calendar",
                color: .white,
                iconColor: .black,
                stroke: true,
                isOn: $settings.isCalendarLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.calendar"
            )
        }
    }

    private var displayOptionsCard: some View {
        SettingsCard(title: "settings.activities.calendar.displayOptions.title") {
            SettingsMenuRow(
                title: "settings.activities.calendar.noticeMinutes",
                description: "settings.activities.calendar.noticeMinutes.desc",
                options: [0, 5, 10, 15, 30, 60],
                optionTitle: { minutes in
                    switch minutes {
                    case 0:
                        return LocalizedStringKey("settings.activities.calendar.noticeMinutes.atStart")
                    case 5:
                        return LocalizedStringKey("settings.activities.calendar.noticeMinutes.5m")
                    case 10:
                        return LocalizedStringKey("settings.activities.calendar.noticeMinutes.10m")
                    case 15:
                        return LocalizedStringKey("settings.activities.calendar.noticeMinutes.15m")
                    case 30:
                        return LocalizedStringKey("settings.activities.calendar.noticeMinutes.30m")
                    case 60:
                        return LocalizedStringKey("settings.activities.calendar.noticeMinutes.oneHour")
                    default:
                        return LocalizedStringKey("settings.activities.calendar.noticeMinutes.15m")
                    }
                },
                accessibilityIdentifier: "settings.activities.calendar.noticeMinutes",
                selection: $settings.noticeMinutes
            )
            
            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.activities.calendar.timeDisplayFormat",
                description: "settings.activities.calendar.timeDisplayFormat.desc",
                options: CalendarTimeDisplayFormat.allCases,
                optionTitle: { format in
                    LocalizedStringKey(format.localizationKey)
                },
                accessibilityIdentifier: "settings.activities.calendar.timeDisplayFormat",
                selection: $settings.timeDisplayFormat
            )
            
            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.activities.calendar.ongoingEventHideMinutes",
                description: "settings.activities.calendar.ongoingEventHideMinutes.desc",
                options: [0, 5, 10, 15],
                optionTitle: { minutes in
                    switch minutes {
                    case 0:
                        return LocalizedStringKey("settings.activities.calendar.ongoing.untilEnd")
                    case 5:
                        return LocalizedStringKey("settings.activities.calendar.ongoing.5m")
                    case 10:
                        return LocalizedStringKey("settings.activities.calendar.ongoing.10m")
                    case 15:
                        return LocalizedStringKey("settings.activities.calendar.ongoing.15m")
                    default:
                        return LocalizedStringKey("settings.activities.calendar.ongoing.untilEnd")
                    }
                },
                accessibilityIdentifier: "settings.activities.calendar.ongoingEventHideMinutes",
                selection: $settings.ongoingEventHideMinutes
            )
        }
    }

    private var privacyAndSoundCard: some View {
        SettingsCard(title: "settings.activities.calendar.privacyAndNotifications.title") {
            SettingsToggleRow(
                title: "settings.activities.calendar.privacyMode",
                description: "settings.activities.calendar.privacyMode.desc",
                systemImage: "eye.slash",
                color: .purple,
                isOn: $settings.isPrivacyModeEnabled,
                accessibilityIdentifier: "settings.activities.calendar.privacyMode"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "settings.activities.calendar.soundAlert",
                description: "settings.activities.calendar.soundAlert.desc",
                systemImage: "speaker.wave.2",
                color: .orange,
                isOn: $settings.isSoundAlertEnabled,
                accessibilityIdentifier: "settings.activities.calendar.soundAlert"
            )
        }
    }
}
