//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

enum HomePages: String, CaseIterable, Hashable, Codable, Identifiable {
    case camera
    case localTimer
    case calendar
    case vpn
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .camera: return "Camera"
        case .localTimer: return "Timer"
        case .calendar: return "Calendar"
        case .vpn: return "VPN"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .camera: return "Quickly access the camera."
        case .localTimer: return "Set a quick timer."
        case .calendar: return "View upcoming events."
        case .vpn: return "Manage VPN connections."
        }
    }
    
    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .localTimer: return "timer"
        case .calendar: return "calendar"
        case .vpn: return "network.badge.shield.half.filled"
        }
    }
    
    var tint: Color {
        switch self {
        case .camera: return .blue
        case .localTimer: return .orange
        case .calendar: return .red
        case .vpn: return .purple
        }
    }
}

struct HomePageNotchView: View {
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let localTimerViewModel: LocalTimerViewModel
    let calendarViewModel: CalendarViewModel
    
    @State private var currentPage: HomePages?
    
    init(notchViewModel: NotchViewModel, settings: HomePageSettingsStore, localTimerViewModel: LocalTimerViewModel, calendarViewModel: CalendarViewModel, initialPage: HomePages) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.localTimerViewModel = localTimerViewModel
        self.calendarViewModel = calendarViewModel
        self._currentPage = State(initialValue: initialPage)
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
                    ForEach(activePages, id: \.self) { page in
                        pageView(for: page)
                            .clipped()
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)
            .onChange(of: currentPage) { oldPage, newPage in
                guard let newPage = newPage else { return }
                notchViewModel.send(
                    .showLiveActivity(
                        HomePageNotchContent(
                            notchViewModel: notchViewModel,
                            settings: settings,
                            homePages: newPage,
                            localTimerViewModel: localTimerViewModel,
                            calendarViewModel: calendarViewModel
                        )
                    )
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isDynamicIsland ? 24 : 26))
        .padding(.horizontal, isDynamicIsland ? 10 : 35)
        .padding(.bottom, 10)
        .onDisappear {
            let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
            notchViewModel.send(
                .showLiveActivity(
                    HomePageNotchContent(
                        notchViewModel: notchViewModel,
                        settings: settings,
                        homePages: activePages.first ?? .camera,
                        localTimerViewModel: localTimerViewModel,
                        calendarViewModel: calendarViewModel
                    )
                )
            )
        }
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel, settings: settings, localTimerViewModel: localTimerViewModel, calendarViewModel: calendarViewModel)
        case .localTimer:
            LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel)
        case .calendar:
            CalendarNotchView(calendarViewModel: calendarViewModel, notchViewModel: notchViewModel)
        case .vpn:
            VpnPageNotchView(notchViewModel: notchViewModel)
        }
    }
}
