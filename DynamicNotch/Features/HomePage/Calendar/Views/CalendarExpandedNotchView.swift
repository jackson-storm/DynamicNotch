import SwiftUI
internal import EventKit

struct CalendarExpandedNotchView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    let notchViewModel: NotchViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            if let event = calendarViewModel.nextEvent {
                HStack {
                    title(event: event)
                    Spacer()
                    buttons(event: event)
                }
            } else {
                Text("No upcoming events")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(.leading, isDynamicIsland ? 30 : 48)
        .padding(.trailing, isDynamicIsland ? 30 : 45)
        .padding(.bottom, isDynamicIsland ? 20 : 18)
    }
    
    @ViewBuilder
    private func title(event: EKEvent) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !event.title.isEmpty {
                MarqueeText(
                    .constant(event.title),
                    font: .system(size: 20, weight: .bold),
                    nsFont: .headline,
                    textColor: .white,
                    backgroundColor: .clear,
                    minDuration: 2.0,
                    frameWidth: 200
                )
            } else {
                Text("Empty Title")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.gray.opacity(0.6))
                    .lineLimit(1)
            }
            
            HStack(spacing: 16) {
                if event.isAllDay {
                    Text("All Day")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                } else {
                    Text(timeString(from: event.startDate) + " - " + timeString(from: event.endDate))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 10, height: 10)
                    
                    Text(event.calendar.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            if let location = event.location, !location.isEmpty {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    MarqueeText(
                        .constant(location),
                        font: .system(size: 12),
                        nsFont: .headline,
                        textColor: .gray.opacity(0.8),
                        backgroundColor: .clear,
                        minDuration: 3.0,
                        frameWidth: 200
                    )
                }
            } else {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("Empty Location")
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func buttons(event: EKEvent) -> some View {
        HStack {
            Button {
                calendarViewModel.deleteEvent(event)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .gray.opacity(0.3)))

            if let url = event.url, isVideoCall(url: url) {
                Button {
                    NSWorkspace.shared.open(url)
                    notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.calendar.id))
                } label: {
                    HStack {
                        Image(systemName: "video.fill")
                        Text("Join Meeting")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
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
