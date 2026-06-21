import SwiftUI
internal import EventKit

struct CalendarMinimalNotchView: View {
    @Environment(\.notchScale) private var notchScale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: isDynamicIsland ? 16 : 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            if calendarViewModel.nextEvent != nil {
                Text(calendarViewModel.formattedNextEventTime)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.red)
                    .monospacedDigit()
            }
        }
        .padding(.trailing, isDynamicIsland ? 6.scaled(by: notchScale) : 14.scaled(by: notchScale))
        .padding(.leading, isDynamicIsland ? 8.scaled(by: notchScale) : 14.scaled(by: notchScale))
    }
}
