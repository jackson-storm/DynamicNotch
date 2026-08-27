import SwiftUI
import Combine
internal import AppKit
import UniformTypeIdentifiers

struct NotchView: View {
    let notchEventCoordinator: NotchEventCoordinator
    let powerViewModel: PowerViewModel
    let bluetoothViewModel: BluetoothViewModel
    let wifiViewModel: WifiViewModel
    let vpnViewModel: VpnViewModel
    let downloadViewModel: DownloadViewModel
    let focusViewModel: FocusViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let timerViewModel: TimerViewModel
    let screenRecordingViewModel: ScreenRecordingViewModel
    let lockScreenManager: LockScreenManager
    let homePageViewModel: HomePageViewModel
    
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @ObservedObject var airDropController: NotchAirDropController
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        ZStack(alignment: .top) {
            NotchInteractiveBodyView(
                notchViewModel: notchViewModel,
                settingsViewModel: settingsViewModel
            )
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
                NotchDragAndDropDestinationOverlay(
                    airDropViewModel: airDropViewModel,
                    airDropController: airDropController,
                    settingsViewModel: settingsViewModel
                )
            }
            .onChange(of: notchViewModel.displayedContent?.id) {
                notchViewModel.handleStrokeVisibility()
            }
            .onChange(of: settingsViewModel.notchWidth) {
                notchViewModel.updateDimensions()
            }
            .onChange(of: settingsViewModel.notchHeight) {
                notchViewModel.updateDimensions()
            }
            .onChange(of: settingsViewModel.application.notchShapeStyle) {
                notchViewModel.updateDimensions()
            }
            
            HomePagePageIndicatorView(
                notchViewModel: notchViewModel,
                settingsViewModel: settingsViewModel
            )
            .transition(
                notchViewModel.contentTransition(
                    notchHeight: notchViewModel.presentedNotchSize.height,
                    baseHeight: notchViewModel.notchModel.baseHeight,
                    isExpandedPresentation: notchViewModel.isDisplayingExpandedLiveActivity
                )
            )
            .zIndex(settingsViewModel.homePage.homePageScrollAxis == .vertical ? 1.0 : -1.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
