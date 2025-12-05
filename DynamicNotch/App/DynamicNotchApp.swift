import SwiftUI

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var screenCapture = ScreenCaptureManager()
    @StateObject private var windowModel = WindowModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenCapture)
                .environmentObject(windowModel)
                .background(WindowAccessor { window in
                    windowModel.attach(window: window)
                })
                .ignoresSafeArea()
                .task {
                    do {
                        try await screenCapture.requestPermissionAndStart()
                    } catch {
                        print("Screen capture failed to start:", error)
                    }
                }
        }
        .windowStyle(.plain)
    }
}
