import Cocoa
import SwiftUI

enum SettingsScene {
    static let id = "settings"
}

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isMenuBarIconVisible") var isMenuBarIconVisible: Bool = true
    
    var body: some Scene {
        MenuBarExtra("Dynamic Notch", systemImage: "rectangle.topthird.inset.filled", isInserted: $isMenuBarIconVisible) {
            MenuBarMenu(applicationSettings: appDelegate.settingsViewModel.application)
                .environment(\.locale, appDelegate.settingsViewModel.application.appLanguage.locale)
        }

        WindowGroup(id: SettingsScene.id) {
            SettingsRootView(
                powerService: appDelegate.powerService,
                settingsViewModel: appDelegate.settingsViewModel,
                notchViewModel: appDelegate.notchViewModel,
                notchEventCoordinator: appDelegate.notchEventCoordinator,
                bluetoothViewModel: appDelegate.bluetoothViewModel,
                networkViewModel: appDelegate.networkViewModel,
                downloadViewModel: appDelegate.downloadViewModel,
                nowPlayingViewModel: appDelegate.nowPlayingViewModel,
                lockScreenManager: appDelegate.lockScreenManager
            )
            .frame(width: SettingsWindowLayout.width, height: SettingsWindowLayout.height)
        }
        .defaultSize(width: SettingsWindowLayout.width, height: SettingsWindowLayout.height)
        .windowResizability(.contentSize)
    }
}

private struct MenuBarMenu: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    var body: some View {
        Group {
            Button {
                openWindow(id: SettingsScene.id)
            } label: {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .environment(\.locale, applicationSettings.appLanguage.locale)
    }
}
