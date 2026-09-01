import Foundation
internal import AppKit
#if canImport(ApplicationServices)
import ApplicationServices
#endif
import OSLog

@MainActor
final class ClockTimerController: ClockTimerControlling {
    private enum Control {
        case pauseResume
        case stop

        var buttonIdentifier: String {
            switch self {
            case .pauseResume:
                "PauseResumeButton"
            case .stop:
                "CancelButton"
            }
        }

        var debugName: String {
            switch self {
            case .pauseResume:
                "pause/resume"
            case .stop:
                "stop"
            }
        }
    }

    private let logger = Logger(subsystem: "com.dynamicnotch.app", category: "ClockTimerController")
    private let workspace: NSWorkspace
    private let buttonSearchAttempts: Int
    private let buttonSearchIntervalNanoseconds: UInt64
    private let clockBundleIdentifier = "com.apple.clock"
    private let runningTimerURL = URL(string: "clock-timer-running:")!

    init(
        workspace: NSWorkspace = .shared,
        buttonSearchAttempts: Int = 20,
        buttonSearchIntervalNanoseconds: UInt64 = 100_000_000
    ) {
        self.workspace = workspace
        self.buttonSearchAttempts = max(buttonSearchAttempts, 1)
        self.buttonSearchIntervalNanoseconds = buttonSearchIntervalNanoseconds
    }

    func togglePauseResume() async -> Bool {
        await perform(.pauseResume)
    }

    func stopTimer() async -> Bool {
        await perform(.stop)
    }
}

private extension ClockTimerController {
    private func perform(_ control: Control) async -> Bool {
        #if canImport(ApplicationServices)
        guard AXIsProcessTrusted() else {
            logger.warning("Accessibility permission is required to \(control.debugName, privacy: .public) the Clock timer.")
            return false
        }
        #else
        return false
        #endif

        let previousFrontmostApp = workspace.frontmostApplication
        let clockWasHidden = clockApplication?.isHidden ?? false

        if let button = findButton(identifier: control.buttonIdentifier) {
            return press(button, control: control)
        }

        let didOpenRunningTimer = workspace.open(runningTimerURL)
        guard didOpenRunningTimer else {
            logger.error("Failed to surface the running Clock timer before attempting to \(control.debugName, privacy: .public).")
            return false
        }

        let button = await waitForButton(identifier: control.buttonIdentifier)
        let didPerformAction = button.map { press($0, control: control) } ?? false

        if !didPerformAction {
            logger.error("Unable to find the Clock timer \(control.debugName, privacy: .public) control after surfacing Clock.")
        }

        restorePreviousFrontmostApp(
            previousFrontmostApp,
            clockWasHidden: clockWasHidden
        )

        return didPerformAction
    }

    var clockApplication: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: clockBundleIdentifier).first
    }

    func waitForButton(identifier: String) async -> AXUIElement? {
        for _ in 0..<buttonSearchAttempts {
            if let button = findButton(identifier: identifier) {
                return button
            }

            try? await Task.sleep(nanoseconds: buttonSearchIntervalNanoseconds)
        }

        return nil
    }

    func findButton(identifier: String) -> AXUIElement? {
        guard let clockApplication else { return nil }

        let appElement = AXUIElementCreateApplication(clockApplication.processIdentifier)
        let focusedWindow: AXUIElement? = axAttribute(kAXFocusedWindowAttribute, from: appElement)
        let windows: [AXUIElement] = axAttribute(kAXWindowsAttribute, from: appElement) ?? []

        if let focusedWindow, let button = findButton(identifier: identifier, in: focusedWindow) {
            return button
        }

        for window in windows {
            if let button = findButton(identifier: identifier, in: window) {
                return button
            }
        }

        return nil
    }

    func findButton(identifier: String, in element: AXUIElement) -> AXUIElement? {
        let role: String = axAttribute(kAXRoleAttribute, from: element) ?? ""
        let elementIdentifier: String = axAttribute(kAXIdentifierAttribute, from: element) ?? ""

        if role == kAXButtonRole as String, elementIdentifier == identifier {
            return element
        }

        let children: [AXUIElement] = axAttribute(kAXChildrenAttribute, from: element) ?? []
        for child in children {
            if let button = findButton(identifier: identifier, in: child) {
                return button
            }
        }

        return nil
    }

    private func press(_ button: AXUIElement, control: Control) -> Bool {
        let didPress = AXUIElementPerformAction(button, kAXPressAction as CFString) == .success

        if !didPress {
            logger.error("Clock timer \(control.debugName, privacy: .public) action failed.")
        }

        return didPress
    }

    func restorePreviousFrontmostApp(
        _ previousFrontmostApp: NSRunningApplication?,
        clockWasHidden: Bool
    ) {
        if clockWasHidden {
            clockApplication?.hide()
        }

        guard let previousFrontmostApp,
              previousFrontmostApp.bundleIdentifier != clockBundleIdentifier else {
            return
        }

        previousFrontmostApp.activate()
    }

    func axAttribute<T>(_ attribute: String, from element: AXUIElement) -> T? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value as? T
    }
}
