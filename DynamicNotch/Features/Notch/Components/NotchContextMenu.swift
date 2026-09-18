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
}
