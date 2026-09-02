import SwiftUI

struct NotchSurfaceContainerView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        notchSurface
            .overlay {
                contentOverlayWrapped
            }
    }
    
    @ViewBuilder
    private var notchSurface: some View {
        let isDynamicIsland = notchViewModel.isDynamicIsland
        
        NotchBackgroundSurface(
            style: settingsViewModel.application.notchBackgroundStyle,
            topCornerRadius: notchViewModel.interactiveCornerRadius.top,
            bottomCornerRadius: notchViewModel.interactiveCornerRadius.bottom,
            isDynamicIsland: isDynamicIsland,
            dynamicIslandCornerRadius: notchViewModel.dynamicIslandCornerRadius,
            strokeColor: shouldShowStroke ? visibleStrokeColor : .clear,
            strokeWidth: settingsViewModel.notchStrokeWidth,
            height: notchViewModel.interactiveNotchSize.height,
            baseHeight: notchViewModel.notchModel.baseHeight
        )
        .scaleEffect(
            x: shouldApplyPressScale ? notchViewModel.pressScale : 1,
            y: shouldApplyPressScale ? notchViewModel.pressScale : 1,
            anchor: .top
        )
    }
    
    @ViewBuilder
    private var contentOverlayWrapped: some View {
        if notchViewModel.isDynamicIsland {
            contentOverlay
                .environment(\.isDynamicIsland, true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask {
                    DynamicIslandShape(
                        cornerRadius: max(0, notchViewModel.dynamicIslandCornerRadius - 2)
                    )
                    .padding(3)
                    .scaleEffect(
                        x: shouldApplyPressScale ? notchViewModel.pressScale : 1,
                        y: shouldApplyPressScale ? notchViewModel.pressScale : 1,
                        anchor: .top
                    )
                }
        } else {
            contentOverlay
                .environment(\.isDynamicIsland, false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask {
                    NotchShape(
                        topCornerRadius: max(0, notchViewModel.interactiveCornerRadius.top - 2),
                        bottomCornerRadius: max(0, notchViewModel.interactiveCornerRadius.bottom - 2)
                    )
                    .padding(.horizontal, 5)
                    .padding(.bottom, 3)
                    .scaleEffect(
                        x: shouldApplyPressScale ? notchViewModel.pressScale : 1,
                        y: shouldApplyPressScale ? notchViewModel.pressScale : 1,
                        anchor: .top
                    )
                }
        }
    }
    
    @ViewBuilder
    private var contentOverlay: some View {
        if let content = notchViewModel.displayedContent {
            renderedContentView(for: content)
                .scaleEffect(
                    x: shouldApplyPressScale ? notchViewModel.pressScale : 1,
                    y: shouldApplyPressScale ? notchViewModel.pressScale : 1,
                    anchor: .top
                )
                .resizeAwareBlur(
                    size: notchViewModel.interactiveNotchSize,
                    baseHeight: notchViewModel.notchModel.baseHeight,
                    isResizeEffectEnabled: content.usesContentResizeEffect,
                    interactiveBlur: notchViewModel.contentResizeBlurRadius,
                    interactiveOpacity: notchViewModel.contentResizeOpacity,
                    swipeProgress: notchViewModel.easedSwipeStretchProgress,
                    swipeInteraction: notchViewModel.swipeInteraction
                )
                .id(notchViewModel.displayedPresentationID)
                .transition(
                    notchViewModel.contentTransition(
                        notchHeight: notchViewModel.presentedNotchSize.height,
                        baseHeight: notchViewModel.notchModel.baseHeight,
                        isExpandedPresentation: notchViewModel.isDisplayingExpandedLiveActivity
                    )
                )
        }
    }
    
    @MainActor
    @ViewBuilder
    private func renderedContentView(for content: NotchContentProtocol) -> some View {
        Group {
            if notchViewModel.isDisplayingExpandedLiveActivity {
                content.makeExpandedView()
            } else {
                content.makeView()
            }
        }
        .id(content.id)
    }
    
    private var shouldApplyPressScale: Bool {
        let isExpandedPresentation = notchViewModel.isDisplayingExpandedLiveActivity
        let isPresentationHidden = (notchViewModel.isActivityPresentationHidden && !notchViewModel.isLocked) && notchViewModel.displayedContent == nil
        let isScreenshotContent = notchViewModel.displayedContent?.id == NotchContentRegistry.Screenshot.active.id
        return !isExpandedPresentation && !isPresentationHidden && !isScreenshotContent
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
    
    private var shouldShowStroke: Bool {
        let isStrokeEnabled = settingsViewModel.application.isShowNotchStrokeEnabled
        return isStrokeEnabled && notchViewModel.shouldRenderStroke
    }
}
