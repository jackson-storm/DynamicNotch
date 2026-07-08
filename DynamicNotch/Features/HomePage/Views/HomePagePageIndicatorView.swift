import SwiftUI

struct HomePagePageIndicatorView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    @State private var isHovering = false
    @State private var hoveredPage: HomePages? = nil
    @State private var isPressed = false

    var body: some View {
        if shouldShowPageIndicator, let currentPage {
            let size = settingsViewModel.homePage.homePageIndicatorSize
            
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
            .padding(size.padding)
            .background(Color.black)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(shouldShowStroke ? visibleStrokeColor : .clear, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(isHovering ? 1.2 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isPressed = true
                        let itemWidth = size.dotSize + size.spacing
                        let relativeX = value.location.x - size.padding
                        let index = Int(relativeX / itemWidth)
                        let clampedIndex = max(0, min(activePages.count - 1, index))
                        let page = activePages[clampedIndex]
                        
                        if page != currentPage {
                            switchToPage(page)
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
    
    private func switchToPage(_ page: HomePages) {
        guard let homePageContent = homePageContent else { return }
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
