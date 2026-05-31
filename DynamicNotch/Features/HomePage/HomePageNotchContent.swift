//
//  HomePageNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI
internal import EventKit

struct HomePageNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.HomePage.active.id
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let homePages: HomePages
    let localTimerViewModel: LocalTimerViewModel
    let calendarViewModel: CalendarViewModel
    
    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }
    
    var strokeColor: Color {
        if notchViewModel.isDisplayingExpandedLiveActivity {
            return .white.opacity(0.2)
        }
        return .white.opacity(0)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 44)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth, height: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch homePages {
        case .camera:
            let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
            let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
            
            if !isStarted {
                return .init(width: baseWidth + 65, height: baseHeight + 125)
            }
            if isLarge {
                return .init(width: baseWidth + 250, height: baseHeight + 220)
            } else {
                return .init(width: baseWidth + 180, height: baseHeight + 180)
            }
            
        case .localTimer:
            return .init(width: baseWidth + 100, height: baseHeight + 125)
            
        case .calendar:
            if calendarViewModel.authorizationStatus != .fullAccess {
                return .init(width: baseWidth + 60, height: baseHeight + 125)
                
            } else {
                return .init(width: baseWidth + 130, height: baseHeight + 125)
            }
        }
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch homePages {
        case .camera:
            let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
            let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
            
            if !isStarted {
                return .init(width: baseWidth + 95, height: baseHeight + 125)
            }
            if isLarge {
                return .init(width: baseWidth + 280, height: baseHeight + 220)
            } else {
                return .init(width: baseWidth + 210, height: baseHeight + 180)
            }
            
        case .localTimer:
            return .init(width: baseWidth + 140, height: baseHeight + 125)
            
        case .calendar:
            if calendarViewModel.authorizationStatus != .fullAccess {
                return .init(width: baseWidth + 90, height: baseHeight + 125)
                
            } else {
                return .init(width: baseWidth + 160, height: baseHeight + 125)
            }
        }
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            HomePageNotchView(
                notchViewModel: notchViewModel,
                settings: settings,
                localTimerViewModel: localTimerViewModel,
                calendarViewModel: calendarViewModel,
                initialPage: homePages
            )
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
