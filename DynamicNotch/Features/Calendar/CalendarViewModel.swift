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
    
    func fetchUpcomingEvents() {
        guard authorizationStatus == .fullAccess else { return }
        
        let now = Date()
        let daysToShow = UserDefaults.standard.object(forKey: GeneralSettingsStorage.Keys.calendarDaysToShow) as? Int ?? GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarDaysToShow] as! Int
        let showAllDay = UserDefaults.standard.object(forKey: GeneralSettingsStorage.Keys.calendarShowAllDay) as? Bool ?? GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.calendarShowAllDay] as! Bool
        
        guard let endDate = Calendar.current.date(byAdding: .day, value: daysToShow, to: now) else { return }
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: calendars)
        
        var fetchedEvents = eventStore.events(matching: predicate)
            .filter { $0.endDate > now }
        
        if !showAllDay {
            fetchedEvents = fetchedEvents.filter { !$0.isAllDay }
        }
        
        // Sort by start date
        fetchedEvents.sort { $0.startDate < $1.startDate }
        
        self.events = fetchedEvents
        
        // Find the next upcoming event (or currently running one if we want to show it)
        // Usually, the next event is the first one in the sorted list.
        self.nextEvent = fetchedEvents.first
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
        
        // Listen for settings changes (days to show, all day)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Debounce or just fetch, it's cheap enough for typical calendar sizes
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
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.startDate)
    }
    
    var hasUpcomingEvent: Bool {
        guard let event = nextEvent else { return false }
        // For example, only show live activity if event is starting within next 30 mins
        // Or if it is currently running. Let's just say if it's within 1 hour or currently running.
        let now = Date()
        let timeUntilStart = event.startDate.timeIntervalSince(now)
        let timeUntilEnd = event.endDate.timeIntervalSince(now)
        
        // Is currently running
        if timeUntilStart <= 0 && timeUntilEnd > 0 {
            return true
        }
        
        // Starts within 60 minutes
        if timeUntilStart > 0 && timeUntilStart <= 3600 {
            return true
        }
        
        return false
    }
    
    @MainActor
    func openCalendarEvent() {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        } else if let url = URL(string: "ical://") {
            NSWorkspace.shared.open(url)
        }
    }

    func deleteEvent(_ event: EKEvent) {
        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
            // Immediately update the UI locally, the system will also trigger .EKEventStoreChanged
            self.events.removeAll { $0.eventIdentifier == event.eventIdentifier }
            if self.nextEvent?.eventIdentifier == event.eventIdentifier {
                self.nextEvent = self.events.first
            }
        } catch {
            print("Failed to delete event: \(error.localizedDescription)")
        }
    }
}
