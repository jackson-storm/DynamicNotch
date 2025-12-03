import SwiftUI

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NotchContentView()
                .ignoresSafeArea()
        }
        .windowStyle(.plain)
    }
}
