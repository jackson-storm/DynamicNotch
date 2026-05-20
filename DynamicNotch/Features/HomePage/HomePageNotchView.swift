//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

enum HomePages: CaseIterable, Hashable {
    case camera
    case localTimer
    case notes
}

struct HomePageNotchView: View {
    let notchViewModel: NotchViewModel
    let localTimerViewModel: LocalTimerViewModel
    
    @State private var currentPage: HomePages?
    
    init(notchViewModel: NotchViewModel, localTimerViewModel: LocalTimerViewModel, initialPage: HomePages) {
        self.notchViewModel = notchViewModel
        self.localTimerViewModel = localTimerViewModel
        self._currentPage = State(initialValue: initialPage)
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(HomePages.allCases, id: \.self) { page in
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
                            homePages: newPage,
                            localTimerViewModel: localTimerViewModel
                        )
                    )
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, bottomPadding)
        .onDisappear {
            notchViewModel.send(
                .showLiveActivity(
                    HomePageNotchContent(
                        notchViewModel: notchViewModel,
                        homePages: .camera,
                        localTimerViewModel: localTimerViewModel
                    )
                )
            )
        }
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel, localTimerViewModel: localTimerViewModel)
        case .localTimer:
            LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel)
        case .notes:
            NotesNotchView()
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch currentPage {
        case .camera:
            35
        case .localTimer:
            35
        case .notes:
            40
        case .none:
            0
        }
    }
    
    private var bottomPadding: CGFloat {
        switch currentPage {
        case .camera:
            10
        case .localTimer:
            10
        case .notes:
            13
        case .none:
            0
        }
    }
}
