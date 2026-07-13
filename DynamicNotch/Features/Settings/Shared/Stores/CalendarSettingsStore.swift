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
    
    func resetCalendar() {
        isCalendarLiveActivityEnabled = GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarLiveActivity] as? Bool ?? true

        showAllDayEvents = GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarShowAllDay] as? Bool ?? true
        daysToShow = GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarDaysToShow] as? Int ?? 7
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
        return (GeneralSettingsStorage.defaultValues[key] as? Int) ?? 7
    }
}
