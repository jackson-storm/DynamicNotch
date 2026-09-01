import Foundation
import Combine

extension CalendarTimeDisplayFormat: StoredSettingValue {}

@MainActor
final class CalendarSettingsStore: SettingsStoreBase {
    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarLiveActivity, defaultValue: true)
    var isCalendarLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarShowAllDay, defaultValue: true)
    var showAllDayEvents: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarDaysToShow, defaultValue: 7)
    var daysToShow: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarNoticeMinutes, defaultValue: 15)
    var noticeMinutes: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarIncludedCalendarIDs, defaultValue: [])
    var includedCalendarIDs: [String]

    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarTimeDisplayFormat, defaultValue: .exact)
    var timeDisplayFormat: CalendarTimeDisplayFormat

    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarOngoingEventHideMinutes, defaultValue: 0)
    var ongoingEventHideMinutes: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarPrivacyMode, defaultValue: false)
    var isPrivacyModeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.calendarSoundAlert, defaultValue: false)
    var isSoundAlertEnabled: Bool

    func resetCalendar() {
        isCalendarLiveActivityEnabled = true
        showAllDayEvents = true
        daysToShow = 7
        noticeMinutes = 15
        includedCalendarIDs = []
        timeDisplayFormat = .exact
        ongoingEventHideMinutes = 0
        isPrivacyModeEnabled = false
        isSoundAlertEnabled = false
    }

    override init(defaults: UserDefaults) {
        super.init(defaults: defaults)
    }
}
