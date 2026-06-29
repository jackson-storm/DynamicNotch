import SwiftUI

struct CalendarNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.HomePage.calendar.id
    let calendarViewModel: CalendarViewModel
    let notchViewModel: NotchViewModel
    
    var priority: Int { NotchContentRegistry.HomePage.calendar.priority }
    var isExpandable: Bool { true }
    
    var windowLink: (@MainActor () -> Void)? {
        return {
            calendarViewModel.openCalendarEvent()
        }
    }
    
    private var isAMPM: Bool {
        let time = calendarViewModel.formattedNextEventTime.lowercased()
        return time.contains("am") || time.contains("pm") || time.contains("a.m.") || time.contains("p.m.")
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraWidth: CGFloat = isAMPM ? 145 : 110
        return .init(width: baseWidth + extraWidth, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight + 90)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 36)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraWidth: CGFloat = isAMPM ? 115 : 90
        return .init(width: baseWidth + extraWidth, height: baseHeight)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.3
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 180, height: baseHeight + 100)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(CalendarMinimalNotchView(calendarViewModel: calendarViewModel))
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(CalendarExpandedNotchView(calendarViewModel: calendarViewModel, notchViewModel: notchViewModel))
    }
}
