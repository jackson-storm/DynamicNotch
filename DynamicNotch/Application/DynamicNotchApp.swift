import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isMenuBarIconVisible") var isMenuBarIconVisible: Bool = true
    
    var body: some Scene {
        MenuBarExtra(isInserted: $isMenuBarIconVisible) {
            MenuBarMenu()
        } label: {
            Image(systemName: "rectangle.topthird.inset.filled")
        }
    }
}
