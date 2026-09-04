//
//  ApplicationActivator.swift
//  DynamicNotch
//

internal import AppKit
import ApplicationServices

@MainActor
final class ApplicationActivator: Sendable {
    static let shared = ApplicationActivator()

    private init() {}

    @discardableResult
    func openOrActivate(bundleIdentifier: String) -> Bool {
        if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            openOrActivate(application: runningApp)
            return true
        }

        guard let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return false
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration, completionHandler: nil)
        return true
    }

    func openOrActivate(application: NSRunningApplication) {
        application.unhide()

        // 1. Deminiaturize any minimized windows via Accessibility
        unminimizeWindows(for: application.processIdentifier)

        // 2. Send kAEReopenApplication ('rapp') event to reopen main window if closed
        sendReopenAppleEvent(to: application.processIdentifier)

        // 3. Open or activate via NSWorkspace or NSRunningApplication
        if let bundleURL = application.bundleURL {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration, completionHandler: nil)
        } else {
            if #available(macOS 14.0, *) {
                application.activate()
            } else {
                _ = application.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }

    private func unminimizeWindows(for pid: pid_t) {
        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return
        }

        for window in windows {
            var minRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minRef) == .success,
               let isMinimized = minRef as? Bool, isMinimized {
                AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            }
        }
    }

    private func sendReopenAppleEvent(to pid: pid_t) {
        var targetPID = pid
        let target = NSAppleEventDescriptor(
            descriptorType: typeKernelProcessID,
            bytes: &targetPID,
            length: MemoryLayout<pid_t>.size
        )

        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kCoreEventClass),
            eventID: AEEventID(kAEReopenApplication),
            targetDescriptor: target,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )

        _ = try? event.sendEvent(options: .noReply, timeout: 0.5)
    }
}
