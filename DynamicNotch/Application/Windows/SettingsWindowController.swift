internal import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    
    private var appDelegate: AppDelegate?
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: SettingsWindowLayout.width, height: SettingsWindowLayout.height),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupDependencies(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        setupContentView()
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = NSLocalizedString("settings.title", comment: "")
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.toolbarStyle = .unified
        window.level = .normal
        
        window.collectionBehavior = [.managed, .participatesInCycle, .fullScreenNone]
        window.hidesOnDeactivate = false
        window.isExcludedFromWindowsMenu = false
        window.isRestorable = true
        window.identifier = NSUserInterfaceItemIdentifier("DynamicNotchSettingsWindow")
        
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        
        window.delegate = self
    }
    
    private func setupContentView() {
        guard let window = window, let appDelegate = appDelegate else { return }
        
        let settingsView = SettingsRootView(
            powerService: appDelegate.powerService,
            settingsViewModel: appDelegate.settingsViewModel,
            notchViewModel: appDelegate.notchViewModel,
            notchEventCoordinator: appDelegate.notchEventCoordinator,
            bluetoothViewModel: appDelegate.bluetoothViewModel,
            wifiViewModel: appDelegate.wifiViewModel,
            vpnViewModel: appDelegate.vpnViewModel,
            downloadViewModel: appDelegate.downloadViewModel,
            nowPlayingViewModel: appDelegate.nowPlayingViewModel,
            timerViewModel: appDelegate.timerViewModel,
            lockScreenManager: appDelegate.lockScreenManager
        )
        .background(.ultraThinMaterial)
        .frame(width: SettingsWindowLayout.width, height: SettingsWindowLayout.height)
        
        let hostingView = NSHostingView(rootView: settingsView)
        window.contentView = hostingView
    }
    
    func showWindow() {
        _ = window

        window?.level = .normal
        window?.collectionBehavior = [.managed, .participatesInCycle, .fullScreenNone]
        window?.standardWindowButton(.zoomButton)?.isEnabled = false
        
        if window?.isVisible == true {
            NSApp.activate(ignoringOtherApps: true)
            window?.orderFrontRegardless()
            window?.makeKeyAndOrderFront(nil)
            return
        }
        
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        window?.center()
        
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeKeyAndOrderFront(nil)
        }
    }
    
    func showWindow(selecting section: SettingsRootViewModel.Section) {
        showWindow()
        NotificationCenter.default.post(name: NSNotification.Name("SelectSettingsSection"), object: section)
    }
    
    override func close() {
        super.close()
        relinquishFocus()
    }
    
    private func relinquishFocus() {
        window?.orderOut(nil)
        
        let shouldShowDock = appDelegate?.settingsViewModel.application.isDockIconVisible ?? false
        if !shouldShowDock {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        relinquishFocus()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        let shouldShowDock = appDelegate?.settingsViewModel.application.isDockIconVisible ?? false
        if !shouldShowDock {
            NSApp.setActivationPolicy(.regular)
        }
    }
}
