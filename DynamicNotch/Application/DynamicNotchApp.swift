import Cocoa
import SwiftUI

enum WindowsScene {
    static let settings = "settings"
}

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isMenuBarIconVisible") var isMenuBarIconVisible: Bool = true
    
    var body: some Scene {
        MenuBarExtra("Dynamic Notch", systemImage: "rectangle.topthird.inset.filled", isInserted: $isMenuBarIconVisible) {
            MenuBarMenu()
        }
        
        WindowGroup(id: WindowsScene.settings) {
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
            .background(.ultraThinMaterial)
            .frame(width: SettingsWindowLayout.width, height: SettingsWindowLayout.height)
        }
        .defaultSize(width: SettingsWindowLayout.width, height: SettingsWindowLayout.height)
        .windowResizability(.contentSize)
    }
}

private struct MenuBarMenu: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Group {
            Text("Version: \(AppVersionText.appVersionText)")
            
            Divider()
            
            Button { openWindow(id: WindowsScene.settings) } label: {
                Image(systemName: "gearshape")
                Text(verbatim: "Settings")
            }
            
            Divider()
            
            Button(action: { AppRelauncher.restartApp() }) {
                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                Text(verbatim: "Restart")
            }
            
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(verbatim: "Quit")
            }
        }
    }
}
