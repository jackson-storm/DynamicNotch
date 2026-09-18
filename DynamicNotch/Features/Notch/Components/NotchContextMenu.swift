import SwiftUI

struct NotchContextMenu: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    let notchEventCoordinator: NotchEventCoordinator?
    @ObservedObject private var updater = SparkleUpdater.shared
    
    var body: some View {
        let locale = settingsViewModel.application.appLanguage.locale
        
        Button {
            updater.checkForUpdates()
        } label: {
            Image(systemName: "arrow.down.circle")
            Text(locale.dn("menuBar.checkForUpdates", fallback: "Check for Updates"))
        }
        .disabled(!updater.canCheckForUpdates)
        
        Button {
            SettingsWindowController.shared.showWindow()
        } label: {
            Image(systemName: "gearshape")
            Text(locale.dn("menuBar.settings", fallback: "Settings"))
        }

        if canShowToolNotch {
            Button {
                notchEventCoordinator?.showToolNotch()
            } label: {
                Image(systemName: "rectangle.grid.2x2")
                Text(locale.dn("menuBar.showToolNotch", fallback: "Show Tool Notch"))
            }
        }

        if canShowDragAndDropToolNotch, let notchEventCoordinator {
            Button {
                notchEventCoordinator.showDragAndDropToolNotch()
            } label: {
                Image(systemName: notchEventCoordinator.dragAndDropToolNotchMenuSystemImage)
                Text(
                    locale.dn(
                        notchEventCoordinator.dragAndDropToolNotchMenuTitleKey,
                        fallback: notchEventCoordinator.dragAndDropToolNotchMenuFallback
                    )
                )
            }
        }

        if canShowFileTrayItemsBrowser, let notchEventCoordinator {
            Button {
                notchEventCoordinator.showFileTrayItemsBrowser()
            } label: {
                Image(systemName: "tray.full.fill")
                Text(locale.dn("menuBar.showTrayItems", fallback: "Show Tray Items"))
            }
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

    private var canShowToolNotch: Bool {
        guard notchEventCoordinator?.canShowToolNotch == true else { return false }
        return notchViewModel.displayedContent?.id != NotchContentRegistry.HomePage.active.id
    }

    private var canShowDragAndDropToolNotch: Bool {
        guard notchEventCoordinator?.canShowDragAndDropToolNotch == true,
              let displayedContent = notchViewModel.displayedContent else { return false }

        return dragAndDropContentIDs.contains(displayedContent.id) == false
    }

    private var canShowFileTrayItemsBrowser: Bool {
        guard notchEventCoordinator?.canShowFileTrayItemsBrowser == true,
              let displayedContent = notchViewModel.displayedContent else { return false }

        return displayedContent.id != NotchContentRegistry.DragAndDrop.trayItemsBrowser.id
    }

    private var dragAndDropContentIDs: Set<String> {
        Set(
            NotchContentRegistry.DragAndDrop.liveActivityIDs + [
                NotchContentRegistry.DragAndDrop.trayActive.id,
                NotchContentRegistry.DragAndDrop.trayItemsBrowser.id,
                NotchContentRegistry.DragAndDrop.airDropTransferActive.id,
                NotchContentRegistry.DragAndDrop.fileConverterActive.id,
                NotchContentRegistry.DragAndDrop.fileConverterConverted.id
            ]
        )
    }
}
