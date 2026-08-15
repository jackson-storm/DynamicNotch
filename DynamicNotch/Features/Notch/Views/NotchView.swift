import SwiftUI
import Combine
internal import AppKit
import UniformTypeIdentifiers

struct NotchView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    @ObservedObject var powerViewModel: PowerViewModel
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var wifiViewModel: WifiViewModel
    @ObservedObject var vpnViewModel: VpnViewModel
    @ObservedObject var downloadViewModel: DownloadViewModel
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @ObservedObject var airDropController: NotchAirDropController
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var timerViewModel: TimerViewModel
    @ObservedObject var screenRecordingViewModel: ScreenRecordingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var homePageViewModel: HomePageViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            notchBody
                .environment(\.notchScale, notchViewModel.notchModel.scale)
                .background(
                    NotchEventHandlersView(
                        notchEventCoordinator: notchEventCoordinator,
                        powerViewModel: powerViewModel,
                        bluetoothViewModel: bluetoothViewModel,
                        wifiViewModel: wifiViewModel,
                        vpnViewModel: vpnViewModel,
                        downloadViewModel: downloadViewModel,
                        focusViewModel: focusViewModel,
                        airDropViewModel: airDropViewModel,
                        settingsViewModel: settingsViewModel,
                        nowPlayingViewModel: nowPlayingViewModel,
                        timerViewModel: timerViewModel,
                        screenRecordingViewModel: screenRecordingViewModel,
                        lockScreenManager: lockScreenManager,
                        homePageViewModel: homePageViewModel
                    )
                )
                .overlay {
                    DragAndDropDestinationView(
                        isTargeted: $airDropController.isTargeted,
                        targetedDropTarget: Binding(
                            get: { airDropViewModel.targetedDropTarget },
                            set: { airDropViewModel.setTargetedDropTarget($0) }
                        ),
                        mode: settingsViewModel.mediaAndFiles.dragAndDropActivityMode,
                        onDropPasteboard: { target, pasteboard in
                            switch target {
                            case .airDrop:
                                guard settingsViewModel.mediaAndFiles.dragAndDropActivityMode.showsAirDrop,
                                      settingsViewModel.mediaAndFiles.isAirDropLiveActivityEnabled else {
                                    return false
                                }
                                
                                return airDropController.handlePasteboardDrop(pasteboard)
                            case .tray:
                                guard settingsViewModel.mediaAndFiles.dragAndDropActivityMode.showsTray,
                                      settingsViewModel.mediaAndFiles.isTrayLiveActivityEnabled else {
                                    return false
                                }
                                
                                return airDropController.handleTrayDrop(
                                    pasteboard,
                                    mode: settingsViewModel.mediaAndFiles.fileTrayUsageMode
                                )
                            }
                        }
                    )
                }
                .onChange(of: notchViewModel.notchModel.content?.id) {
                    notchViewModel.handleStrokeVisibility()
                }
                .onChange(of: settingsViewModel.notchWidth) {
                    notchViewModel.updateDimensions()
                }
                .onChange(of: settingsViewModel.notchHeight) {
                    notchViewModel.updateDimensions()
                }
            
            homePageIndicator
                .zIndex(settingsViewModel.homePage.homePageScrollAxis == .vertical ? 1.0 : -1.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private extension NotchView {
    @ViewBuilder
    var notchBody: some View {
        notchSurface
            .overlay {
                contentOverlayWrapped
            }
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
            .offset(y: notchViewModel.topInset == 0 ? 3 : 1)
            .customNotchMouseSwipeable(
                notchViewModel: notchViewModel,
                isEnabled: shouldEnableNotchSwipeGestures
            )
            .customNotchSwipeDismissable(
                notchViewModel: notchViewModel,
                isEnabled: shouldEnableNotchSwipeGestures
            )
            .contextMenu {
                appContextMenu
            }
            .environment(\.colorScheme, .dark)
            .animation(notchViewModel.animations.strokeVisibility, value: notchViewModel.shouldRenderStroke)
            .animation(notchViewModel.animations.strokeVisibility, value: settingsViewModel.isShowNotchStrokeEnabled)
            .animation(notchViewModel.animations.notchVisibility, value: notchViewModel.showNotch)
    }
    
    @ViewBuilder
    var notchSurface: some View {
        let isDynamicIsland = notchViewModel.topInset == 0
        let isExpandedPresentation = notchViewModel.notchModel.isPresentingExpandedLiveActivity
        let isPresentationHidden = notchViewModel.isActivityPresentationHidden && notchViewModel.notchModel.temporaryNotificationContent == nil
        let isScreenshotContent = notchViewModel.displayedContent?.id == NotchContentRegistry.Screenshot.active.id
        let shouldApplyPressScale = !isExpandedPresentation && !isPresentationHidden && !isScreenshotContent
        
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
    var contentOverlay: some View {
        let isExpandedPresentation = notchViewModel.notchModel.isPresentingExpandedLiveActivity
        let isPresentationHidden = notchViewModel.isActivityPresentationHidden && notchViewModel.notchModel.temporaryNotificationContent == nil
        let isScreenshotContent = notchViewModel.displayedContent?.id == NotchContentRegistry.Screenshot.active.id
        let shouldApplyPressScale = !isExpandedPresentation && !isPresentationHidden && !isScreenshotContent
        
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
                        isExpandedPresentation: notchViewModel.isDisplayingExpandedLiveActivity,
                    )
                )
        }
    }
    
    @ViewBuilder
    var contentOverlayWrapped: some View {
        let isExpandedPresentation = notchViewModel.notchModel.isPresentingExpandedLiveActivity
        let isPresentationHidden = notchViewModel.isActivityPresentationHidden && notchViewModel.notchModel.temporaryNotificationContent == nil
        let isScreenshotContent = notchViewModel.displayedContent?.id == NotchContentRegistry.Screenshot.active.id
        let shouldApplyPressScale = !isExpandedPresentation && !isPresentationHidden && !isScreenshotContent
        
        if notchViewModel.topInset == 0 {
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
    
    @MainActor
    @ViewBuilder
    func renderedContentView(for content: NotchContentProtocol) -> some View {
        if notchViewModel.isDisplayingExpandedLiveActivity {
            content.makeExpandedView()
        } else {
            content.makeView()
        }
    }
    
    @ViewBuilder
    var homePageIndicator: some View {
        HomePagePageIndicatorView(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        .transition(
            notchViewModel.contentTransition(
                notchHeight: notchViewModel.presentedNotchSize.height,
                baseHeight: notchViewModel.notchModel.baseHeight,
                isExpandedPresentation: notchViewModel.isDisplayingExpandedLiveActivity,
            )
        )
    }
    
    @ViewBuilder
    var appContextMenu: some View {
        let locale = settingsViewModel.application.appLanguage.locale
        
        Button {
            SettingsWindowController.shared.showWindow()
        } label: {
            Image(systemName: "gearshape")
            Text(locale.dn("menuBar.settings", fallback: "Settings"))
        }
        
        Divider()
        
        Button(action: { AppRelauncher.restartApp() }) {
            Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
            Text(locale.dn("menuBar.restart", fallback: "Restart"))
        }
        
        Button(action: { NSApp.terminate(nil) }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
            Text(locale.dn("menuBar.quit", fallback: "Quit"))
        }
    }
    
    private var shouldEnableNotchSwipeGestures: Bool {
        guard !notchViewModel.isActivityPresentationHidden || notchViewModel.notchModel.temporaryNotificationContent != nil else { return false }
        
        return !(
            notchViewModel.notchModel.isPresentingExpandedLiveActivity &&
            (notchViewModel.notchModel.content?.id == NotchContentRegistry.DragAndDrop.trayActive.id ||
             (notchViewModel.notchModel.content?.id == NotchContentRegistry.HomePage.active.id && settingsViewModel.homePage.homePageScrollAxis == .vertical))
        )
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
