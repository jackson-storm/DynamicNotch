import Combine
internal import EventKit
import Foundation
import SwiftUI
internal import AppKit

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [EKEvent] = []
    @Published var nextEvent: EKEvent? = nil
    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    
    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    
    init() {
        if authorizationStatus == .fullAccess {
            startAutoRefresh()
        }
    }
    
    func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    if granted {
                        self?.startAutoRefresh()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    if granted {
                        self?.startAutoRefresh()
                    }
                }
            }
        }
    }
    
    private var lastAlertedEventIdentifier: String?

    var availableCalendars: [EKCalendar] {
        guard authorizationStatus == .fullAccess else { return [] }
        return eventStore.calendars(for: .event)
    }

    func fetchUpcomingEvents() {
        guard authorizationStatus == .fullAccess else { return }
        
        let now = Date()
        let daysToShow = UserDefaults.standard.object(forKey: GeneralSettingsStorage.Keys.calendarDaysToShow) as? Int ?? GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarDaysToShow] as! Int
        let showAllDay = UserDefaults.standard.object(forKey: GeneralSettingsStorage.Keys.calendarShowAllDay) as? Bool ?? GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarShowAllDay] as! Bool
        let includedCalendarIDs = UserDefaults.standard.object(forKey: GeneralSettingsStorage.Keys.calendarIncludedCalendarIDs) as? [String] ?? []
        
        guard let endDate = Calendar.current.date(byAdding: .day, value: daysToShow, to: now) else { return }
        
        var calendars = eventStore.calendars(for: .event)
        if !includedCalendarIDs.isEmpty {
            calendars = calendars.filter { includedCalendarIDs.contains($0.calendarIdentifier) }
        }
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: calendars)
        
        var fetchedEvents = eventStore.events(matching: predicate)
            .filter { $0.endDate > now }
        
        if !showAllDay {
            fetchedEvents = fetchedEvents.filter { !$0.isAllDay }
        }
        
        if !dismissedEventIdentifiers.isEmpty {
            fetchedEvents = fetchedEvents.filter { !dismissedEventIdentifiers.contains($0.eventIdentifier) }
        }
        
        // Sort by start date
        fetchedEvents.sort { $0.startDate < $1.startDate }
        
        self.events = fetchedEvents
        self.nextEvent = fetchedEvents.first

        checkSoundAlert()
    }

    private func checkSoundAlert() {
        let isSoundAlertEnabled = UserDefaults.standard.bool(forKey: GeneralSettingsStorage.Keys.calendarSoundAlert)
        guard isSoundAlertEnabled, hasUpcomingEvent, let event = nextEvent else { return }

        if lastAlertedEventIdentifier != event.eventIdentifier {
            lastAlertedEventIdentifier = event.eventIdentifier
            NSSound(named: "Glass")?.play()
        }
    }
    
    func startAutoRefresh() {
        fetchUpcomingEvents()
        
        // Listen for calendar changes from the system
        NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: eventStore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchUpcomingEvents()
            }
            .store(in: &cancellables)
        
        // Listen for settings changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchUpcomingEvents()
            }
            .store(in: &cancellables)
            
        // Setup a timer to refresh every minute to update current/next event
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.fetchUpcomingEvents()
            }
    }
    
    func stopAutoRefresh() {
        cancellables.removeAll()
        timerCancellable?.cancel()
    }
    
    var formattedNextEventTime: String {
        guard let event = nextEvent else { return "" }
        if event.isAllDay {
            return "All Day"
        }
        
        let now = Date()
        let formatRaw = UserDefaults.standard.string(forKey: GeneralSettingsStorage.Keys.calendarTimeDisplayFormat) ?? CalendarTimeDisplayFormat.exact.rawValue
        let format = CalendarTimeDisplayFormat(rawValue: formatRaw) ?? .exact
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let exactTime = formatter.string(from: event.startDate)
        
        let minutesUntilStart = max(0, Int(ceil(event.startDate.timeIntervalSince(now) / 60)))
        let relativeTime: String
        if minutesUntilStart == 0 {
            relativeTime = "Now"
        } else if minutesUntilStart < 60 {
            relativeTime = "in \(minutesUntilStart)m"
        } else {
            let hours = minutesUntilStart / 60
            let mins = minutesUntilStart % 60
            relativeTime = mins > 0 ? "in \(hours)h \(mins)m" : "in \(hours)h"
        }
        
        switch format {
        case .exact:
            return exactTime
        case .relative:
            return relativeTime
        case .both:
            return "\(exactTime) · \(relativeTime)"
        }
    }

    var isPrivacyModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: GeneralSettingsStorage.Keys.calendarPrivacyMode)
    }

    func displayTitle(for event: EKEvent) -> String {
        if isPrivacyModeEnabled {
            return "Calendar Event"
        }
        return event.title.isEmpty ? "Empty Title" : event.title
    }

    func displayLocation(for event: EKEvent) -> String? {
        if isPrivacyModeEnabled {
            return nil
        }
        return event.location
    }
    
    var hasUpcomingEvent: Bool {
        guard let event = nextEvent else { return false }
        let now = Date()
        let timeUntilStart = event.startDate.timeIntervalSince(now)
        let timeUntilEnd = event.endDate.timeIntervalSince(now)
        
        // Is currently running
        if timeUntilStart <= 0 && timeUntilEnd > 0 {
            let hideMinutes = UserDefaults.standard.object(forKey: GeneralSettingsStorage.Keys.calendarOngoingEventHideMinutes) as? Int ?? 0
            if hideMinutes > 0 {
                let elapsedMinutes = Int(abs(timeUntilStart) / 60)
                if elapsedMinutes >= hideMinutes {
                    return false
                }
            }
            return true
        }
        
        let noticeMinutes = UserDefaults.standard.object(forKey: GeneralSettingsStorage.Keys.calendarNoticeMinutes) as? Int ?? GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarNoticeMinutes] as! Int
        let maxSeconds = TimeInterval(noticeMinutes * 60)
        
        // Starts within configured notice time
        if timeUntilStart > 0 && timeUntilStart <= maxSeconds {
            return true
        }
        
        return false
    }
    
    @MainActor
    func openCalendarEvent() {
        if !ApplicationActivator.shared.openOrActivate(bundleIdentifier: "com.apple.iCal"),
           let url = URL(string: "ical://") {
            NSWorkspace.shared.open(url)
        }
    }

    @Published var dismissedEventIdentifiers: Set<String> = []
    
    func dismissEvent(_ event: EKEvent) {
        dismissedEventIdentifiers.insert(event.eventIdentifier)
        self.events.removeAll { $0.eventIdentifier == event.eventIdentifier }
        if self.nextEvent?.eventIdentifier == event.eventIdentifier {
            self.nextEvent = self.events.first
        }
    }
}
