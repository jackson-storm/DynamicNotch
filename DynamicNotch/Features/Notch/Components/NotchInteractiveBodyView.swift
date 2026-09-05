import SwiftUI
internal import AppKit

struct NotchInteractiveBodyView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        NotchSurfaceContainerView(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        .opacity(isVisiblyHiddenInFullscreen ? 0 : 1)
        .shadow(
            color: (notchViewModel.presentedNotchSize.height >= notchViewModel.notchModel.baseHeight + 30)
            ? .black.opacity(0.4) : .clear, radius: 20
        )
        .frame(
            width: notchViewModel.presentedNotchSize.width,
            height: notchViewModel.presentedNotchSize.height
        )
        .customNotchPressable(
            notchViewModel: notchViewModel,
            isPressed: $notchViewModel.isPressed,
            baseSize: notchViewModel.presentedNotchSize
        )
        .offset(y: notchViewModel.isDynamicIsland ? 3 : 1)
        .customNotchMouseSwipeable(
            notchViewModel: notchViewModel,
            isEnabled: shouldEnableNotchSwipeGestures
        )
        .customNotchSwipeDismissable(
            notchViewModel: notchViewModel,
            isEnabled: shouldEnableNotchSwipeGestures
        )
        .contextMenu {
            NotchContextMenu(settingsViewModel: settingsViewModel)
        }
        .environment(\.colorScheme, .dark)
        .animation(notchViewModel.animations.strokeVisibility, value: notchViewModel.shouldRenderStroke)
        .animation(notchViewModel.animations.strokeVisibility, value: settingsViewModel.isShowNotchStrokeEnabled)
        .animation(notchViewModel.animations.notchVisibility, value: notchViewModel.showNotch)
    }
    
    private var isVisiblyHiddenInFullscreen: Bool {
        guard settingsViewModel.application.isDynamicIslandHiddenInFullscreenEnabled else { return false }
        guard let screen = NSScreen.preferredNotchScreen(for: settingsViewModel) ?? NSScreen.main else { return false }
        return SkyLightOperator.shared.isFullscreenSpaceActive(on: screen) && !notchViewModel.hasDisplayedContent
    }
    
    private var shouldEnableNotchSwipeGestures: Bool {
        guard (!notchViewModel.isActivityPresentationHidden || notchViewModel.isLocked) || notchViewModel.notchModel.temporaryNotificationContent != nil else { return false }
        
        return !(
            notchViewModel.isDisplayingExpandedLiveActivity &&
            (notchViewModel.displayedContent?.id == NotchContentRegistry.DragAndDrop.trayActive.id ||
             (notchViewModel.displayedContent?.id == NotchContentRegistry.HomePage.active.id && settingsViewModel.homePage.homePageScrollAxis == .vertical))
        )
    }
}
