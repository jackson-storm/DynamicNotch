import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            TabView {
                NotchControlPanel(
                    notchViewModel: appDelegate.notchViewModel,
                    notchEventCoordinator: appDelegate.notchEventCoordinator
                )
                .tabItem {
                    Image(systemName: "light.panel")
                    Text("Notch Panel")
                }
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
            }
            .frame(width: 600, height: 400)
            .background(.ultraThinMaterial)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}
