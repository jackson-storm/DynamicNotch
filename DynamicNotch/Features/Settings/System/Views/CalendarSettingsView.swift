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
        SettingsCard(title: "settings.calendar.card.activity") {
            SettingsToggleRow(
                title: "settings.calendar.activity.title",
                description: "settings.calendar.activity.desc",
                systemImage: "calendar",
                color: .blue,
                stroke: true,
                isOn: $settings.isCalendarLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.calendar"
            )
        }
    }

    private var displayOptionsCard: some View {
        SettingsCard(title: "settings.calendar.card.displayOptions") {
            SettingsMenuRow(
                title: "settings.calendar.noticeMinutes.title",
                description: "settings.calendar.noticeMinutes.desc",
                options: [0, 5, 10, 15, 30, 60],
                optionTitle: { minutes in
                    switch minutes {
                    case 0:
                        return LocalizedStringKey("settings.calendar.noticeMinutes.atStart")
                    case 5:
                        return LocalizedStringKey("settings.calendar.noticeMinutes.5m")
                    case 10:
                        return LocalizedStringKey("settings.calendar.noticeMinutes.10m")
                    case 15:
                        return LocalizedStringKey("settings.calendar.noticeMinutes.15m")
                    case 30:
                        return LocalizedStringKey("settings.calendar.noticeMinutes.30m")
                    case 60:
                        return LocalizedStringKey("settings.calendar.noticeMinutes.oneHour")
                    default:
                        return LocalizedStringKey("settings.calendar.noticeMinutes.15m")
                    }
                },
                accessibilityIdentifier: "settings.activities.calendar.noticeMinutes",
                selection: $settings.noticeMinutes
            )
            
            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.calendar.timeDisplayFormat.title",
                description: "settings.calendar.timeDisplayFormat.desc",
                options: CalendarTimeDisplayFormat.allCases,
                optionTitle: { format in
                    LocalizedStringKey(format.localizationKey)
                },
                accessibilityIdentifier: "settings.activities.calendar.timeDisplayFormat",
                selection: $settings.timeDisplayFormat
            )
            
            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.calendar.ongoingHide.title",
                description: "settings.calendar.ongoingHide.desc",
                options: [0, 5, 10, 15],
                optionTitle: { minutes in
                    switch minutes {
                    case 0:
                        return LocalizedStringKey("settings.calendar.ongoing.untilEnd")
                    case 5:
                        return LocalizedStringKey("settings.calendar.ongoing.5m")
                    case 10:
                        return LocalizedStringKey("settings.calendar.ongoing.10m")
                    case 15:
                        return LocalizedStringKey("settings.calendar.ongoing.15m")
                    default:
                        return LocalizedStringKey("settings.calendar.ongoing.untilEnd")
                    }
                },
                accessibilityIdentifier: "settings.activities.calendar.ongoingEventHideMinutes",
                selection: $settings.ongoingEventHideMinutes
            )
        }
    }

    private var privacyAndSoundCard: some View {
        SettingsCard(title: "settings.calendar.card.privacy") {
            SettingsToggleRow(
                title: "settings.calendar.privacyMode.title",
                description: "settings.calendar.privacyMode.desc",
                systemImage: "eye.slash",
                color: .black,
                stroke: true,
                isOn: $settings.isPrivacyModeEnabled,
                accessibilityIdentifier: "settings.activities.calendar.privacyMode"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "settings.calendar.soundAlert.title",
                description: "settings.calendar.soundAlert.desc",
                systemImage: "speaker.wave.2.fill",
                color: .red,
                isOn: $settings.isSoundAlertEnabled,
                accessibilityIdentifier: "settings.activities.calendar.soundAlert"
            )
        }
    }
}
