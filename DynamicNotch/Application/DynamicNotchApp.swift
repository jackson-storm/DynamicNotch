import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            TabView {
                #if DEBUG
                DebugPanelSettingsView(notchViewModel: appDelegate.notchViewModel, notchEventCoordinator: appDelegate.notchEventCoordinator)
                .tabItem {
                    Image(systemName: "lock.rectangle.stack")
                    Text("Debug Panel")
                }
                .frame(width: 600, height: 400)
                #endif
                
                GeneralSettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("General")
                    }
                    .frame(width: 600, height: 600)
                
                LiveActivitySettingsView()
                    .tabItem {
                        Image(systemName: "livephoto")
                        Text("Live Activity")
                    }
                    .frame(width: 600, height: 600)
                
                TemporarySettingsView()
                    .tabItem {
                        Image(systemName: "bell")
                        Text("Temp Activity")
                    }
                    .frame(width: 600, height: 600)
                
                AboutAppSettingsView()
                    .tabItem {
                        Image(systemName: "info.circle")
                        Text("About App")
                    }
                    .frame(width: 600, height: 600)
            }
            .background(.ultraThinMaterial)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}
