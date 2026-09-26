import SwiftUI
internal import EventKit

struct CalendarMinimalNotchView: View {
    @Environment(\.notchScale) private var notchScale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @ObservedObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: isNotchlessScreen ? 16 : 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            if calendarViewModel.nextEvent != nil {
                Text(calendarViewModel.formattedNextEventTime)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.red)
                    .monospacedDigit()
            }
        }
        .padding(.leading, isNotchlessScreen ? 6.scaled(by: notchScale) : 14.scaled(by: notchScale))
        .padding(.trailing, isNotchlessScreen ? 6.scaled(by: notchScale) : 14.scaled(by: notchScale))
    }
}
