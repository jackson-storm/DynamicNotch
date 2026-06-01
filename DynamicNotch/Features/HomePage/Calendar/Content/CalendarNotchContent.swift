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
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 110, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight + 85)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 40)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 90, height: baseHeight)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.3
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 180, height: baseHeight + 85)
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
