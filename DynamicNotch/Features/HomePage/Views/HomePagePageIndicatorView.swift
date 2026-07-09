import SwiftUI
internal import AppKit

struct HomePagePageIndicatorView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    @State private var isHovering = false
    @State private var hoveredPage: HomePages? = nil
    @State private var isPressed = false
    @State private var isIndicatorVisible = false

    var body: some View {
        Group {
            if shouldShowPageIndicator && isIndicatorVisible, let currentPage {
                let size = settingsViewModel.homePage.homePageIndicatorSize
                let isVertical = settingsViewModel.homePage.homePageScrollAxis == .vertical
                
                Group {
                    if isVertical {
                        VStack(spacing: size.spacing) {
                            ForEach(activePages, id: \.self) { page in
                                Circle()
                                    .fill(dotColor(for: page, currentPage: currentPage))
                                    .frame(width: size.dotSize, height: size.dotSize)
                                    .scaleEffect(hoveredPage == page ? 1.25 : 1.0)
                                    .contentShape(Rectangle())
                                    .onHover { isHovering in
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                            hoveredPage = isHovering ? page : nil
                                        }
                                    }
                            }
                        }
                    } else {
                        HStack(spacing: size.spacing) {
                            ForEach(activePages, id: \.self) { page in
                                Circle()
                                    .fill(dotColor(for: page, currentPage: currentPage))
                                    .frame(width: size.dotSize, height: size.dotSize)
                                    .scaleEffect(hoveredPage == page ? 1.25 : 1.0)
                                    .contentShape(Rectangle())
                                    .onHover { isHovering in
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                            hoveredPage = isHovering ? page : nil
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(size.padding)
                .background(Color.black)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(shouldShowStroke ? visibleStrokeColor : .clear, lineWidth: 1)
                }
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isPressed = true
                            let itemSize = size.dotSize + size.spacing
                            let relativePos = isVertical ? value.location.y - size.padding : value.location.x - size.padding
                            let index = Int(relativePos / itemSize)
                            let clampedIndex = max(0, min(activePages.count - 1, index))
                            let page = activePages[clampedIndex]
                            
                            if page != currentPage {
                                let isDragging = isVertical ? abs(value.translation.height) > 4 : abs(value.translation.width) > 4
                                switchToPage(page, playHaptic: isDragging)
                            }
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                hoveredPage = page
                            }
                        }
                        .onEnded { _ in
                            isPressed = false
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                hoveredPage = nil
                            }
                        }
                )
                .onHover { hovering in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isHovering = hovering
                    }
                }
                .offset(
                    x: isVertical ? (notchViewModel.presentedNotchSize.width / 2 + indicatorWidth / 2 + (notchViewModel.notchModel.isDynamicIsland ? 8 : -14)) : 0,
                    y: isVertical ? (notchViewModel.presentedNotchSize.height / 2 - indicatorHeight / 2) : (notchViewModel.presentedNotchSize.height + 8)
                )
            }
        }
        .onChange(of: shouldShowPageIndicator) {
            if shouldShowPageIndicator {
                Task {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                        isIndicatorVisible = true
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isIndicatorVisible = false
                }
            }
        }
    }
    private var homePageContent: HomePageNotchContent? {
        notchViewModel.displayedContent as? HomePageNotchContent
    }
    
    private var shouldShowPageIndicator: Bool {
        guard let homePageContent = homePageContent else { return false }
        guard settingsViewModel.homePage.isHomePagePageIndicatorEnabled else { return false }
        guard notchViewModel.isDisplayingExpandedLiveActivity else { return false }
        
        let active = homePageContent.settings.homePageOrder.filter { 
            !homePageContent.settings.homePageDisabled.contains($0) 
        }
        return active.count > 1
    }
    
    private var activePages: [HomePages] {
        guard let homePageContent = homePageContent else { return [] }
        return homePageContent.settings.homePageOrder.filter { 
            !homePageContent.settings.homePageDisabled.contains($0) 
        }
    }

    private var indicatorWidth: CGFloat {
        let size = settingsViewModel.homePage.homePageIndicatorSize
        let count = CGFloat(activePages.count)
        guard count > 0 else { return 0 }
        
        if settingsViewModel.homePage.homePageScrollAxis == .vertical {
            return size.dotSize + size.padding * 2
        } else {
            return size.dotSize * count + size.spacing * (count - 1) + size.padding * 2
        }
    }
    
    private var indicatorHeight: CGFloat {
        let size = settingsViewModel.homePage.homePageIndicatorSize
        let count = CGFloat(activePages.count)
        guard count > 0 else { return 0 }
        
        if settingsViewModel.homePage.homePageScrollAxis == .vertical {
            return size.dotSize * count + size.spacing * (count - 1) + size.padding * 2
        } else {
            return size.dotSize + size.padding * 2
        }
    }
    
    private var currentPage: HomePages? {
        homePageContent?.homePages
    }
    
    private var shouldShowStroke: Bool {
        let isStrokeEnabled = settingsViewModel.application.isShowNotchStrokeEnabled
        return isStrokeEnabled && notchViewModel.shouldRenderStroke
    }
    
    private var visibleStrokeColor: Color {
        let strokeOpacity = settingsViewModel.application.notchStrokeOpacity
        let isDefaultStroke = settingsViewModel.application.isDefaultActivityStrokeEnabled
        
        let baseColor: Color
        if isDefaultStroke {
            baseColor = .white.opacity(0.2)
        } else {
            baseColor = notchViewModel.displayedContent?.strokeColor ?? notchViewModel.cachedStrokeColor
        }
        return baseColor.opacity(strokeOpacity)
    }
    
    private func dotColor(for page: HomePages, currentPage: HomePages) -> Color {
        if page == currentPage {
            return Color.white
        } else if hoveredPage == page {
            return Color.white.opacity(0.8)
        } else {
            return Color.white.opacity(0.4)
        }
    }
    
    private func switchToPage(_ page: HomePages, playHaptic: Bool) {
        guard let homePageContent = homePageContent else { return }
        
        if playHaptic {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        }

        notchViewModel.send(
            .showLiveActivity(
                HomePageNotchContent(
                    notchViewModel: notchViewModel,
                    settings: settingsViewModel.homePage,
                    homePages: page,
                    localTimerViewModel: homePageContent.localTimerViewModel
                )
            )
        )
    }
}
