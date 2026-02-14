import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .frame(width: 600, height: 500)
        }
        .defaultPosition(.center)
        .defaultSize(width: 600, height: 500)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
