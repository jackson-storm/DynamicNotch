import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isMenuBarIconVisible") var isMenuBarIconVisible: Bool = true
    
    var body: some Scene {
        MenuBarExtra("Dynamic Notch", systemImage: "rectangle.topthird.inset.filled", isInserted: $isMenuBarIconVisible) {
            MenuBarMenu()
        }

        Settings {
            SettingsRootView(
                powerService: appDelegate.powerService,
                generalSettingsViewModel: appDelegate.generalSettingsViewModel,
                notchViewModel: appDelegate.notchViewModel,
                notchEventCoordinator: appDelegate.notchEventCoordinator,
                bluetoothViewModel: appDelegate.bluetoothViewModel,
                networkViewModel: appDelegate.networkViewModel,
                nowPlayingViewModel: appDelegate.nowPlayingViewModel,
                lockScreenManager: appDelegate.lockScreenManager
            )
            .frame(width: SettingsWindowLayout.width, height: SettingsWindowLayout.height)
        }
    }
}

private struct MenuBarMenu: View {
    var body: some View {
        SettingsLink {
            Image(systemName: "gearshape")
            Text("Settings")
        }
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
