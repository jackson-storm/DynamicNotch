import SwiftUI
internal import EventKit

struct CalendarExpandedNotchView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.locale) private var locale
    
    let notchViewModel: NotchViewModel
    
    var body: some View {
        VStack {
            if let event = calendarViewModel.nextEvent {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        title(event: event)
                        clock(event: event)
                        location(event: event)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    buttons(event: event)
                }
            } else {
                Text(locale.dn("notch.calendar.noEvents", fallback: "No upcoming events"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(.top, isNotchlessScreen ? 0 : 20)
        .padding(.leading, isNotchlessScreen ? 20 : 45)
        .padding(.trailing, isNotchlessScreen ? 10 : 35)
    }
    
    @ViewBuilder
    private func title(event: EKEvent) -> some View {
        let displayTitle = calendarViewModel.displayTitle(for: event)
        MarqueeText(
            .constant(displayTitle),
            font: .system(size: 18, weight: .bold),
            nsFont: .headline,
            textColor: .white,
            backgroundColor: .clear,
            minDuration: 2.0,
            frameWidth: 200
        )
    }
    
    @ViewBuilder
    private func clock(event: EKEvent) -> some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            if event.isAllDay {
                Text(locale.dn("notch.calendar.allDay", fallback: "All Day"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
            } else {
                Text(timeString(from: event.startDate) + " - " + timeString(from: event.endDate))
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder
    private func location(event: EKEvent) -> some View {
        if let location = calendarViewModel.displayLocation(for: event), !location.isEmpty {
            MarqueeText(
                .constant(location),
                font: .system(size: 12),
                nsFont: .headline,
                textColor: .gray.opacity(0.8),
                backgroundColor: .clear,
                minDuration: 4.0,
                frameWidth: 200
            )
        } else {
            Text(calendarViewModel.isPrivacyModeEnabled ? locale.dn("notch.calendar.privateEvent", fallback: "Private Event") : locale.dn("notch.calendar.emptyLocation", fallback: "Empty Location"))
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(.gray.opacity(0.8))
        }
    }
    
    @ViewBuilder
    private func buttons(event: EKEvent) -> some View {
        VStack {
            if let url = event.url, isVideoCall(url: url) {
                Button {
                    NSWorkspace.shared.open(url)
                    notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Calendar.upcoming.id))
                } label: {
                    Image(systemName: "video.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                }
                .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .green.opacity(0.25)))
                
            } else {
                Button {} label: {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .gray.opacity(0.3)))
                .disabled(true)
            }
            
            Button {
                calendarViewModel.dismissEvent(event)
                notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Calendar.upcoming.id))
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.red)
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .red.opacity(0.25)))
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func isVideoCall(url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("zoom.us") ||
        host.contains("meet.google.com") ||
        host.contains("teams.microsoft.com") ||
        host.contains("webex.com")
    }
}
