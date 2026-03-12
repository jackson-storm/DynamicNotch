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
        
        WindowGroup(id: "settingsWindow") {
            SettingsRootView(
                notchViewModel: appDelegate.notchViewModel,
                powerService: appDelegate.powerService,
                notchEventCoordinator: appDelegate.notchEventCoordinator,
                generalSettingsViewModel: appDelegate.generalSettingsViewModel
            )
            .frame(width: 500, height: 560)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}

private struct MenuBarMenu: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button {
            openWindow(id: "settingsWindow")
        } label: {
            Image(systemName: "gearshape")
            Text("Settings")
        }
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
