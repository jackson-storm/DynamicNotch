//
//  HomePageNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

struct HomePageNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.HomePage.active.id
    let notchViewModel: NotchViewModel
    let homePages: HomePages
    let localTimerViewModel: LocalTimerViewModel
    
    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }
    
    var strokeColor: Color {
        if notchViewModel.isDisplayingExpandedLiveActivity {
            return .white.opacity(0.2)
        }
        return .white.opacity(0)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        switch homePages {
        case .camera:
            return (top: 24, bottom: 44)
        case .localTimer:
            return (top: 24, bottom: 44)
        case .notes:
            return (top: 30, bottom: 40)
        }
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch homePages {
        case .camera:
            return .init(width: baseWidth, height: baseHeight)
        case .localTimer:
            return .init(width: baseWidth, height: baseHeight)
        case .notes:
            return .init(width: baseWidth, height: baseHeight)
        }
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch homePages {
        case .camera:
            let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
            if !isStarted {
                return .init(width: baseWidth + 65, height: baseHeight + 125)
            }
            let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
            if isLarge {
                return .init(width: baseWidth + 250, height: baseHeight + 220)
            } else {
                return .init(width: baseWidth + 180, height: baseHeight + 180)
            }
        case .localTimer:
            return .init(width: baseWidth + 100, height: baseHeight + 125)
        case .notes:
            return .init(width: baseWidth + 150, height: baseHeight + 200)
        }
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            HomePageNotchView(
                notchViewModel: notchViewModel,
                localTimerViewModel: localTimerViewModel,
                initialPage: homePages
            )
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
