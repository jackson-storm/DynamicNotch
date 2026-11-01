import SwiftUI
import Combine
internal import AppKit
import UniformTypeIdentifiers

struct NotchView: View {
    let notchEventCoordinator: NotchEventCoordinator
    let homePageTools: HomePageTools
    
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
            .onChange(of: settingsViewModel.application.notchWidth) { _, _ in
                notchViewModel.updateDimensions()
            }
            .onChange(of: settingsViewModel.application.notchHeight) { _, _ in
                notchViewModel.updateDimensions()
            }
            
            HomePagePageIndicatorView(
                notchViewModel: notchViewModel,
                settingsViewModel: settingsViewModel
            )
            .environment(\.isNotchlessScreen, notchViewModel.isDynamicIsland)
            .transition(
                notchViewModel.contentTransition(
                    notchWidth: notchViewModel.presentedNotchSize.width,
                    notchHeight: notchViewModel.presentedNotchSize.height,
                    baseWidth: notchViewModel.notchModel.baseWidth,
                    baseHeight: notchViewModel.notchModel.baseHeight,
                    isExpandedPresentation: notchViewModel.isDisplayingExpandedLiveActivity
                )
            )
            .zIndex(1.0)
        }
        .environmentObject(homePageTools)
        .environment(\.locale, settingsViewModel.application.appLanguage.locale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
