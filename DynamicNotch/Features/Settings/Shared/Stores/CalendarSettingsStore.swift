import Foundation
import Combine

@MainActor
final class CalendarSettingsStore: SettingsStoreBase {
    @Published var isCalendarLiveActivityEnabled: Bool {
        didSet {
            persist(isCalendarLiveActivityEnabled, for: GeneralSettingsStorage.Keys.calendarLiveActivity)
        }
    }

    
    @Published var showAllDayEvents: Bool {
        didSet {
            persist(showAllDayEvents, for: GeneralSettingsStorage.Keys.calendarShowAllDay)
        }
    }
    
    @Published var daysToShow: Int {
        didSet {
            persist(daysToShow, for: GeneralSettingsStorage.Keys.calendarDaysToShow)
        }
    }
    
    @Published var noticeMinutes: Int {
        didSet {
            persist(noticeMinutes, for: GeneralSettingsStorage.Keys.calendarNoticeMinutes)
        }
    }
    
    @Published var includedCalendarIDs: [String] {
        didSet {
            persist(includedCalendarIDs, for: GeneralSettingsStorage.Keys.calendarIncludedCalendarIDs)
        }
    }
    
    @Published var timeDisplayFormat: CalendarTimeDisplayFormat {
        didSet {
            persist(timeDisplayFormat.rawValue, for: GeneralSettingsStorage.Keys.calendarTimeDisplayFormat)
        }
    }
    
    @Published var ongoingEventHideMinutes: Int {
        didSet {
            persist(ongoingEventHideMinutes, for: GeneralSettingsStorage.Keys.calendarOngoingEventHideMinutes)
        }
    }
    
    @Published var isPrivacyModeEnabled: Bool {
        didSet {
            persist(isPrivacyModeEnabled, for: GeneralSettingsStorage.Keys.calendarPrivacyMode)
        }
    }
    
    @Published var isSoundAlertEnabled: Bool {
        didSet {
            persist(isSoundAlertEnabled, for: GeneralSettingsStorage.Keys.calendarSoundAlert)
        }
    }
    
    func resetCalendar() {
        isCalendarLiveActivityEnabled = GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarLiveActivity] as? Bool ?? true

        showAllDayEvents = GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarShowAllDay] as? Bool ?? true
        daysToShow = GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarDaysToShow] as? Int ?? 7
        noticeMinutes = GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarNoticeMinutes] as? Int ?? 15
        includedCalendarIDs = GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarIncludedCalendarIDs] as? [String] ?? []
        timeDisplayFormat = .exact
        ongoingEventHideMinutes = 0
        isPrivacyModeEnabled = false
        isSoundAlertEnabled = false
    }
    
    override init(defaults: UserDefaults) {
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
        
        self.isCalendarLiveActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.calendarLiveActivity
        )
        

        
        self.showAllDayEvents = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.calendarShowAllDay
        )
        
        self.daysToShow = Self.resolvedInt(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.calendarDaysToShow
        )
        
        self.noticeMinutes = Self.resolvedInt(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.calendarNoticeMinutes
        )

        self.includedCalendarIDs = (defaults.object(forKey: GeneralSettingsStorage.Keys.calendarIncludedCalendarIDs) as? [String]) ?? []
        
        let formatRaw = (defaults.object(forKey: GeneralSettingsStorage.Keys.calendarTimeDisplayFormat) as? String) ?? CalendarTimeDisplayFormat.exact.rawValue
        self.timeDisplayFormat = CalendarTimeDisplayFormat(rawValue: formatRaw) ?? .exact

        self.ongoingEventHideMinutes = Self.resolvedInt(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.calendarOngoingEventHideMinutes
        )

        self.isPrivacyModeEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.calendarPrivacyMode
        )

        self.isSoundAlertEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.calendarSoundAlert
        )
        
        super.init(defaults: defaults)
    }
    
    private static func resolvedBool(defaults: UserDefaults, key: String) -> Bool {
        if let currentValue = defaults.object(forKey: key) as? Bool {
            return currentValue
        }
        return (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
    }
    
    private static func resolvedInt(defaults: UserDefaults, key: String) -> Int {
        if let currentValue = defaults.object(forKey: key) as? Int {
            return currentValue
        }
        return (GeneralSettingsStorage.defaultValues[key] as? Int) ?? 0
    }
}
