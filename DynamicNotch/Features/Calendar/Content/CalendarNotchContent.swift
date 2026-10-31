import SwiftUI

struct CalendarNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Calendar.upcoming.id
    let calendarViewModel: CalendarViewModel
    let notchViewModel: NotchViewModel
    
    var priority: Int { NotchContentRegistry.Calendar.upcoming.priority }
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
    
    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraWidth: CGFloat = isAMPM ? 140 : 105
        return .init(width: baseWidth + extraWidth, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight + 105)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraWidth: CGFloat = isAMPM ? 140 : 105
        return .init(width: baseWidth + extraWidth, height: baseHeight)
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 230, height: baseHeight + 85)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 36)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.3
    }
    
    @MainActor
    func compactView() -> AnyView {
        AnyView(CalendarMinimalNotchView(calendarViewModel: calendarViewModel))
    }
    
    @MainActor
    func expandedView() -> AnyView {
        AnyView(CalendarExpandedNotchView(calendarViewModel: calendarViewModel, notchViewModel: notchViewModel))
    }
}
