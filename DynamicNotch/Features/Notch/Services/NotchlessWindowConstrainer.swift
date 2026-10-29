//
//  NotchlessWindowConstrainer.swift
//  DynamicNotch
//

internal import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import QuartzCore

private let axObserverCallback: AXObserverCallback = { observer, element, notification, refcon in
    guard let refcon else { return }
    let constrainer = Unmanaged<NotchlessWindowConstrainer>.fromOpaque(refcon).takeUnretainedValue()
    if Thread.isMainThread {
        MainActor.assumeIsolated {
            constrainer.handleAXNotification(element: element, notification: notification as String)
        }
    } else {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                constrainer.handleAXNotification(element: element, notification: notification as String)
            }
        }
    }
}

private let mouseEventTapCallback: CGEventTapCallBack = { proxy, type, event, refcon in
    guard let refcon else { return Unmanaged.passRetained(event) }
    let constrainer = Unmanaged<NotchlessWindowConstrainer>.fromOpaque(refcon).takeUnretainedValue()
    if Thread.isMainThread {
        return MainActor.assumeIsolated {
            constrainer.handleMouseEvent(proxy: proxy, type: type, event: event)
        }
    } else {
        return Unmanaged.passRetained(event)
    }
}

private struct AXWindowKey: Hashable {
    let element: AXUIElement

    static func == (lhs: AXWindowKey, rhs: AXWindowKey) -> Bool {
        CFEqual(lhs.element, rhs.element)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(element))
    }
}

private struct ActiveWindowDragSession {
    let window: AXUIElement
    let clickOffsetY: CGFloat
    let isResizeTop: Bool
    let canSnap: Bool
    let initialSize: CGSize
    let initialMouseDownLoc: CGPoint
    let restorableSize: CGSize?
    var hasRestoredSnap: Bool = false
    var isPushingAgainstTopSnap: Bool = false
    var targetSnapScreen: NSScreen?
}

@MainActor
final class NotchlessWindowConstrainer {
    private let settings: ApplicationSettingsStore
    private let snapPreviewManager = WindowSnapPreviewManager()
    private var preSnapSizes: [AXWindowKey: CGSize] = [:]
    private var observers: [pid_t: AXObserver] = [:]
    private var runLoopSources: [pid_t: CFRunLoopSource] = [:]
    private var mouseUpMonitor: Any?
    private var mouseEventTap: CFMachPort?
    private var mouseEventRunLoopSource: CFRunLoopSource?
    private var activeDragSession: ActiveWindowDragSession?
    private let systemWideElement = AXUIElementCreateSystemWide()

    private var cancellables = Set<AnyCancellable>()
    private var retryTimer: AnyCancellable?
    private var isApplyingConstraint = false
    private var isRunning = false
    private var windowAnimationTimer: DispatchSourceTimer?

    init(settings: ApplicationSettingsStore) {
        self.settings = settings
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        bindSettings()
        setupWorkspaceNotifications()
        setupMouseUpMonitor()

        if AXIsProcessTrusted() {
            registerAllRunningApplications()
            setupMouseEventTap()
            constrainAllVisibleWindows()
        } else {
            startAccessibilityRetryTimer()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        cancelWindowAnimation()
        snapPreviewManager.hideImmediately()
        preSnapSizes.removeAll()
        retryTimer?.cancel()
        retryTimer = nil
        cancellables.removeAll()

        if let mouseUpMonitor {
            NSEvent.removeMonitor(mouseUpMonitor)
            self.mouseUpMonitor = nil
        }

        teardownMouseEventTap()
        unregisterAllApplications()
    }

    // MARK: - Bindings & Notifications

    private func bindSettings() {
        settings.$isNotchlessWindowMarginEnabled
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isEnabled in
                guard let self else { return }
                if isEnabled {
                    self.setupMouseEventTap()
                    self.constrainAllVisibleWindows()
                } else {
                    self.snapPreviewManager.hideImmediately()
                    self.preSnapSizes.removeAll()
                    self.activeDragSession = nil
                }
            }
            .store(in: &cancellables)

        settings.$notchlessWindowMarginOffset
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.settings.isNotchlessWindowMarginEnabled else { return }
                self.constrainAllVisibleWindows()
            }
            .store(in: &cancellables)
    }

    private func setupWorkspaceNotifications() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .receive(on: RunLoop.main)
            .sink { [weak self] app in
                self?.registerApp(app)
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .receive(on: RunLoop.main)
            .sink { [weak self] app in
                self?.unregisterApp(pid: app.processIdentifier)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.settings.isNotchlessWindowMarginEnabled else { return }
                self.constrainAllVisibleWindows()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if AXIsProcessTrusted() {
                    if self.observers.isEmpty {
                        self.retryTimer?.cancel()
                        self.retryTimer = nil
                        self.registerAllRunningApplications()
                        self.constrainAllVisibleWindows()
                    }
                    if self.mouseEventTap == nil {
                        self.setupMouseEventTap()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func setupMouseUpMonitor() {
        if mouseUpMonitor == nil {
            mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.snapPreviewManager.hideImmediately()
                    self.constrainFrontmostWindow()
                }
            }
        }
    }

    private func startAccessibilityRetryTimer() {
        retryTimer?.cancel()
        retryTimer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if AXIsProcessTrusted() {
                    self.retryTimer?.cancel()
                    self.retryTimer = nil
                    self.registerAllRunningApplications()
                    self.setupMouseEventTap()
                    self.constrainAllVisibleWindows()
                }
            }
    }

    // MARK: - Real-Time Mouse Event Tap

    private func setupMouseEventTap() {
        guard mouseEventTap == nil, AXIsProcessTrusted() else { return }

        let eventMask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                                     (1 << CGEventType.leftMouseDragged.rawValue) |
                                     (1 << CGEventType.leftMouseUp.rawValue)

        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: mouseEventTapCallback,
            userInfo: selfPtr
        ) else {
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            self.mouseEventRunLoopSource = source
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        self.mouseEventTap = tap
    }

    private func teardownMouseEventTap() {
        cancelWindowAnimation()
        snapPreviewManager.hideImmediately()
        if let tap = mouseEventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            self.mouseEventTap = nil
        }
        if let source = mouseEventRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            self.mouseEventRunLoopSource = nil
        }
        activeDragSession = nil
    }

    func handleMouseEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let mouseEventTap {
                CGEvent.tapEnable(tap: mouseEventTap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        guard settings.isNotchlessWindowMarginEnabled else {
            snapPreviewManager.hideImmediately()
            activeDragSession = nil
            return Unmanaged.passRetained(event)
        }

        switch type {
        case .leftMouseDown:
            cancelWindowAnimation()
            activeDragSession = nil
            snapPreviewManager.hideImmediately()
            let loc = event.location

            var elementRef: AXUIElement?
            guard AXUIElementCopyElementAtPosition(systemWideElement, Float(loc.x), Float(loc.y), &elementRef) == .success,
                  let element = elementRef else {
                return Unmanaged.passRetained(event)
            }

            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
            let role = roleRef as? String

            if role == "AXTextField" || role == "AXTextArea" {
                return Unmanaged.passRetained(event)
            }

            var windowRef: CFTypeRef?
            let windowElement: AXUIElement
            if AXUIElementCopyAttributeValue(element, kAXWindowAttribute as CFString, &windowRef) == .success,
               let win = windowRef {
                windowElement = (win as! AXUIElement)
            } else if role == (kAXWindowRole as String) {
                windowElement = element
            } else {
                return Unmanaged.passRetained(event)
            }

            var pid: pid_t = 0
            AXUIElementGetPid(windowElement, &pid)
            guard pid != ProcessInfo.processInfo.processIdentifier else {
                return Unmanaged.passRetained(event)
            }

            var subroleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(windowElement, kAXSubroleAttribute as CFString, &subroleRef)
            if let subrole = subroleRef as? String,
               subrole == "AXSystemDialog" || subrole == "AXFloatingWindow" || subrole == "AXUnknown" {
                return Unmanaged.passRetained(event)
            }

            var posRef: CFTypeRef?
            var sizeRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posRef) == .success,
                  AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef) == .success,
                  let posVal = posRef, let sizeVal = sizeRef else {
                return Unmanaged.passRetained(event)
            }

            var pos = CGPoint.zero
            var size = CGSize.zero
            guard AXValueGetValue(posVal as! AXValue, .cgPoint, &pos),
                  AXValueGetValue(sizeVal as! AXValue, .cgSize, &size),
                  size.width >= 100, size.height >= 100 else {
                return Unmanaged.passRetained(event)
            }

            let relX = loc.x - pos.x
            let relY = loc.y - pos.y

            guard relX >= -10 && relX <= size.width + 10 else {
                return Unmanaged.passRetained(event)
            }

            let windowKey = AXWindowKey(element: windowElement)
            var restorableSize: CGSize? = nil
            if let savedSize = preSnapSizes[windowKey] {
                let currentScreen = screen(forAxPoint: loc)
                if let currentScreen {
                    let extraOffset = windowMarginOffset
                    let snappedWidth = currentScreen.visibleFrame.width
                    let snappedHeight = max(100, currentScreen.visibleFrame.height - extraOffset)
                    if abs(size.width - snappedWidth) < 25 && abs(size.height - snappedHeight) < 25 {
                        restorableSize = savedSize
                    } else {
                        preSnapSizes.removeValue(forKey: windowKey)
                    }
                }
            }

            var isSizeSettable: DarwinBoolean = false
            let isSettable = AXUIElementIsAttributeSettable(windowElement, kAXSizeAttribute as CFString, &isSizeSettable) == .success && isSizeSettable.boolValue
            let canSnap = isSettable || size.width >= 150

            if relY >= -4 && relY <= 3 {
                activeDragSession = ActiveWindowDragSession(
                    window: windowElement,
                    clickOffsetY: 0,
                    isResizeTop: true,
                    canSnap: false,
                    initialSize: size,
                    initialMouseDownLoc: loc,
                    restorableSize: nil
                )
            } else if relY > 3 && relY <= max(80, min(120, size.height * 0.35)) {
                activeDragSession = ActiveWindowDragSession(
                    window: windowElement,
                    clickOffsetY: relY,
                    isResizeTop: false,
                    canSnap: canSnap,
                    initialSize: size,
                    initialMouseDownLoc: loc,
                    restorableSize: restorableSize
                )
            }

        case .leftMouseDragged:
            guard var drag = activeDragSession else { break }
            let loc = event.location

            if let restorable = drag.restorableSize, !drag.hasRestoredSnap {
                let moveDown = loc.y - drag.initialMouseDownLoc.y
                let moveDist = hypot(loc.x - drag.initialMouseDownLoc.x, loc.y - drag.initialMouseDownLoc.y)
                if moveDown >= 6 || moveDist >= 12 {
                    drag.hasRestoredSnap = true
                    activeDragSession = drag
                    preSnapSizes.removeValue(forKey: AXWindowKey(element: drag.window))
                    restoreWindowSize(window: drag.window, targetSize: restorable, cursorLoc: loc, initialClickOffsetY: drag.clickOffsetY)
                }
            }

            let currentScreen = screen(forAxPoint: loc)

            if let currentScreen, currentScreen.isNotchless {
                let topLimit = minAllowedTopY(for: currentScreen)
                let minMouseY = topLimit + (drag.isResizeTop ? 0 : drag.clickOffsetY)

                if loc.y < minMouseY {
                    var clamped = loc
                    clamped.y = minMouseY
                    event.location = clamped

                    if !drag.isResizeTop && drag.canSnap {
                        let screenRect = axScreenRect(for: currentScreen)
                        let sideMargin: CGFloat = 35
                        let isNearSideEdge = loc.x <= screenRect.minX + sideMargin || loc.x >= screenRect.maxX - sideMargin
                        let pushDistance = minMouseY - loc.y
                        let snapTriggerThreshold: CGFloat = 4

                        if !drag.isPushingAgainstTopSnap {
                            if pushDistance >= snapTriggerThreshold && !isNearSideEdge {
                                drag.isPushingAgainstTopSnap = true
                                drag.targetSnapScreen = currentScreen
                                activeDragSession = drag
                                let targetFrame = snapTargetFrame(for: currentScreen)
                                snapPreviewManager.show(targetFrame: targetFrame)
                            }
                        } else {
                            if pushDistance < 1.5 || isNearSideEdge {
                                drag.isPushingAgainstTopSnap = false
                                drag.targetSnapScreen = nil
                                activeDragSession = drag
                                snapPreviewManager.hide()
                            } else if drag.targetSnapScreen !== currentScreen {
                                drag.targetSnapScreen = currentScreen
                                activeDragSession = drag
                                let targetFrame = snapTargetFrame(for: currentScreen)
                                snapPreviewManager.show(targetFrame: targetFrame)
                            }
                        }
                    }
                } else {
                    if drag.isPushingAgainstTopSnap {
                        drag.isPushingAgainstTopSnap = false
                        drag.targetSnapScreen = nil
                        activeDragSession = drag
                        snapPreviewManager.hide()
                    }
                }
            } else {
                if drag.isPushingAgainstTopSnap {
                    drag.isPushingAgainstTopSnap = false
                    drag.targetSnapScreen = nil
                    activeDragSession = drag
                    snapPreviewManager.hide()
                }
            }

        case .leftMouseUp:
            if let drag = activeDragSession {
                if drag.isPushingAgainstTopSnap, let snapScreen = drag.targetSnapScreen {
                    snapPreviewManager.hideImmediately()
                    let preSnapSize = drag.restorableSize ?? drag.initialSize
                    applyWindowSnap(window: drag.window, on: snapScreen, preSnapSize: preSnapSize)
                } else {
                    snapPreviewManager.hideImmediately()
                    if drag.hasRestoredSnap, let restorable = drag.restorableSize {
                        finalizeRestoredWindow(window: drag.window, targetSize: restorable, cursorLoc: event.location, clickOffsetY: drag.clickOffsetY)
                    } else {
                        constrainWindow(drag.window)
                    }
                }
                activeDragSession = nil
            }

        default:
            break
        }

        return Unmanaged.passRetained(event)
    }

    // MARK: - App Registration

    private func registerAllRunningApplications() {
        let myPid = ProcessInfo.processInfo.processIdentifier
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular, app.processIdentifier != myPid else { continue }
            registerApp(app)
        }
    }

    private func registerApp(_ app: NSRunningApplication) {
        let pid = app.processIdentifier
        guard pid != ProcessInfo.processInfo.processIdentifier,
              app.activationPolicy == .regular,
              observers[pid] == nil else { return }

        var observer: AXObserver?
        let err = AXObserverCreate(pid, axObserverCallback, &observer)
        guard err == .success, let observer else { return }

        let appElement = AXUIElementCreateApplication(pid)
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        _ = AXObserverAddNotification(observer, appElement, kAXWindowMovedNotification as CFString, selfPtr)
        _ = AXObserverAddNotification(observer, appElement, kAXWindowResizedNotification as CFString, selfPtr)
        _ = AXObserverAddNotification(observer, appElement, kAXWindowCreatedNotification as CFString, selfPtr)
        _ = AXObserverAddNotification(observer, appElement, kAXFocusedWindowChangedNotification as CFString, selfPtr)

        let source = AXObserverGetRunLoopSource(observer)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)

        observers[pid] = observer
        runLoopSources[pid] = source
    }

    private func unregisterApp(pid: pid_t) {
        if let source = runLoopSources.removeValue(forKey: pid) {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        observers.removeValue(forKey: pid)
        preSnapSizes = preSnapSizes.filter { key, _ in
            var p: pid_t = 0
            return AXUIElementGetPid(key.element, &p) == .success && p != pid
        }
    }

    private func unregisterAllApplications() {
        for (_, source) in runLoopSources {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSources.removeAll()
        observers.removeAll()
        preSnapSizes.removeAll()
    }

    // MARK: - Window Constraining

    func handleAXNotification(element: AXUIElement, notification: String) {
        guard settings.isNotchlessWindowMarginEnabled else { return }

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String

        if role == (kAXWindowRole as String) {
            constrainWindow(element)
        } else {
            var focusedWindowRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success,
               let focusedWindow = focusedWindowRef {
                constrainWindow(focusedWindow as! AXUIElement)
            }
        }
    }

    func constrainFrontmostWindow() {
        guard settings.isNotchlessWindowMarginEnabled,
              let frontmost = NSWorkspace.shared.frontmostApplication,
              frontmost.activationPolicy == .regular,
              frontmost.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }

        let appElement = AXUIElementCreateApplication(frontmost.processIdentifier)
        var focusedWindowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef) == .success,
           let focusedWindow = focusedWindowRef {
            constrainWindow(focusedWindow as! AXUIElement)
        }
    }

    func constrainAllVisibleWindows() {
        guard settings.isNotchlessWindowMarginEnabled else { return }
        let myPid = ProcessInfo.processInfo.processIdentifier

        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular && app.processIdentifier != myPid {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let windows = windowsRef as? [AXUIElement] else { continue }

            for window in windows {
                constrainWindow(window)
            }
        }
    }

    private func constrainWindow(_ windowElement: AXUIElement) {
        guard !isApplyingConstraint else { return }

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement, kAXRoleAttribute as CFString, &roleRef)
        guard (roleRef as? String) == (kAXWindowRole as String) else { return }

        var subroleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement, kAXSubroleAttribute as CFString, &subroleRef)
        if let subrole = subroleRef as? String {
            if subrole == "AXSystemDialog" || subrole == "AXFloatingWindow" || subrole == "AXUnknown" {
                return
            }
        }

        var minRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(windowElement, kAXMinimizedAttribute as CFString, &minRef) == .success,
           let isMinimized = minRef as? Bool, isMinimized {
            return
        }

        var fullRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(windowElement, "AXFullScreen" as CFString, &fullRef) == .success,
           let isFullScreen = fullRef as? Bool, isFullScreen {
            return
        }

        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posVal = posRef, let sizeVal = sizeRef else {
            return
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(posVal as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeVal as! AXValue, .cgSize, &size) else {
            return
        }

        guard size.width >= 100, size.height >= 100 else { return }

        let probeX = position.x + max(20, min(size.width / 2, size.width - 20))
        let probeY = position.y + 10
        let probePoint = CGPoint(x: probeX, y: probeY)

        let targetScreen = NSScreen.screens.first { axScreenRect(for: $0).contains(probePoint) } ??
                           NSScreen.screens.first { axScreenRect(for: $0).intersects(CGRect(origin: position, size: size)) } ??
                           NSScreen.main

        guard let targetScreen, targetScreen.isNotchless else {
            return
        }

        let minAllowedTopY = minAllowedTopY(for: targetScreen)

        if position.y < minAllowedTopY - 0.5 {
            isApplyingConstraint = true
            defer { isApplyingConstraint = false }

            let deltaY = minAllowedTopY - position.y
            position.y = minAllowedTopY

            if size.height > deltaY {
                size.height = max(150, size.height - deltaY)
            }

            if let newSizeValue = AXValueCreate(.cgSize, &size) {
                AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, newSizeValue)
            }
            if let newPosValue = AXValueCreate(.cgPoint, &position) {
                AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, newPosValue)
            }
        }
    }

    // MARK: - Window Snapping

    private func snapTargetFrame(for screen: NSScreen) -> NSRect {
        let extraOffset = windowMarginOffset
        let bottom = screen.visibleFrame.minY
        let top = screen.visibleFrame.maxY - extraOffset
        let height = max(100, top - bottom)
        return NSRect(
            x: screen.visibleFrame.minX,
            y: bottom,
            width: screen.visibleFrame.width,
            height: height
        )
    }

    private func cancelWindowAnimation() {
        if let timer = windowAnimationTimer {
            timer.cancel()
            windowAnimationTimer = nil
        }
        isApplyingConstraint = false
    }

    private func animateWindowFrame(
        window: AXUIElement,
        from startPos: CGPoint,
        startSize: CGSize,
        to targetPos: CGPoint,
        targetSize: CGSize,
        duration: TimeInterval = 0.18,
        updateTarget: ((_ progress: CGFloat) -> (CGPoint, CGSize))? = nil,
        completion: (() -> Void)? = nil
    ) {
        cancelWindowAnimation()
        isApplyingConstraint = true

        let startTime = CACurrentMediaTime()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(16))

        timer.setEventHandler { [weak self] in
            guard let self else {
                timer.cancel()
                return
            }

            let elapsed = CACurrentMediaTime() - startTime
            let rawProgress = min(1.0, elapsed / duration)
            // Cubic ease-out: 1 - (1 - t)^3
            let easedProgress = CGFloat(1.0 - pow(1.0 - rawProgress, 3))

            var currentTargetPos = targetPos
            var currentTargetSize = targetSize
            if let updateTarget {
                let updated = updateTarget(easedProgress)
                currentTargetPos = updated.0
                currentTargetSize = updated.1
            }

            let currentX = startPos.x + (currentTargetPos.x - startPos.x) * easedProgress
            let currentY = startPos.y + (currentTargetPos.y - startPos.y) * easedProgress
            let currentW = max(100, startSize.width + (currentTargetSize.width - startSize.width) * easedProgress)
            let currentH = max(100, startSize.height + (currentTargetSize.height - startSize.height) * easedProgress)

            let pos = CGPoint(x: currentX, y: currentY)
            let sz = CGSize(width: currentW, height: currentH)

            self.setAXFrame(window: window, position: pos, size: sz)

            if rawProgress >= 1.0 {
                self.windowAnimationTimer?.cancel()
                self.windowAnimationTimer = nil
                self.setAXFrame(window: window, position: currentTargetPos, size: currentTargetSize)
                self.isApplyingConstraint = false
                completion?()
            }
        }

        self.windowAnimationTimer = timer
        timer.resume()
    }

    private func applyWindowSnap(window: AXUIElement, on screen: NSScreen, preSnapSize: CGSize) {
        preSnapSizes[AXWindowKey(element: window)] = preSnapSize
        let topY = minAllowedTopY(for: screen)
        let extraOffset = windowMarginOffset
        let snapWidth = screen.visibleFrame.width
        let snapHeight = max(100, screen.visibleFrame.height - extraOffset)
        let snapX = screen.visibleFrame.minX

        let targetPos = CGPoint(x: snapX, y: topY)
        let targetSize = CGSize(width: snapWidth, height: snapHeight)

        var curPos = targetPos
        var curSize = targetSize
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
           let p = posRef {
            AXValueGetValue(p as! AXValue, .cgPoint, &curPos)
        }
        if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
           let s = sizeRef {
            AXValueGetValue(s as! AXValue, .cgSize, &curSize)
        }

        animateWindowFrame(
            window: window,
            from: curPos,
            startSize: curSize,
            to: targetPos,
            targetSize: targetSize,
            duration: 0.18
        )
    }

    private func restoreWindowSize(window: AXUIElement, targetSize: CGSize, cursorLoc: CGPoint, initialClickOffsetY: CGFloat) {
        var curPos = CGPoint.zero
        var curSize = targetSize
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
           let p = posRef {
            AXValueGetValue(p as! AXValue, .cgPoint, &curPos)
        }
        if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
           let s = sizeRef {
            AXValueGetValue(s as! AXValue, .cgSize, &curSize)
        }

        let clickRatio = max(0.1, min(0.9, (cursorLoc.x - curPos.x) / max(1, curSize.width)))

        func computeTarget(at loc: CGPoint) -> CGPoint {
            let targetX = loc.x - clickRatio * targetSize.width
            let targetY = loc.y - initialClickOffsetY
            return CGPoint(x: targetX, y: targetY)
        }

        let initialTargetPos = computeTarget(at: cursorLoc)

        animateWindowFrame(
            window: window,
            from: curPos,
            startSize: curSize,
            to: initialTargetPos,
            targetSize: targetSize,
            duration: 0.15,
            updateTarget: { _ in
                let currentCursor = CGEvent(source: nil)?.location ?? cursorLoc
                return (computeTarget(at: currentCursor), targetSize)
            }
        )
    }

    private func finalizeRestoredWindow(window: AXUIElement, targetSize: CGSize, cursorLoc: CGPoint, clickOffsetY: CGFloat) {
        cancelWindowAnimation()
        var curPos = CGPoint.zero
        var pRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &pRef) == .success, let p = pRef {
            AXValueGetValue(p as! AXValue, .cgPoint, &curPos)
        }

        var adjustedPos = curPos
        let inset = min(32, targetSize.width / 2)

        if cursorLoc.x < adjustedPos.x {
            adjustedPos.x = max(0, cursorLoc.x - inset)
        } else if cursorLoc.x > adjustedPos.x + targetSize.width {
            adjustedPos.x = cursorLoc.x - (targetSize.width - inset)
        }

        setAXFrame(window: window, position: adjustedPos, size: targetSize)
        constrainWindow(window)
    }

    private func setAXFrame(window: AXUIElement, position: CGPoint, size: CGSize) {
        var pos = position
        var sz = size
        if let posVal = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
        }
        if let sizeVal = AXValueCreate(.cgSize, &sz) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal)
        }
        if let posVal = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
        }
    }

    // MARK: - Geometry Helpers
    
    private var windowMarginOffset: CGFloat {
        CGFloat(settings.notchlessWindowMarginOffset) - 4
    }

    private func minAllowedTopY(for screen: NSScreen) -> CGFloat {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        let screenAxY = primaryHeight - screen.frame.maxY
        let menuBarHeight = max(0, screen.frame.maxY - screen.visibleFrame.maxY)
        let extraOffset = windowMarginOffset
        return screenAxY + menuBarHeight + extraOffset
    }

    private func axScreenRect(for screen: NSScreen) -> CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        let sx = screen.frame.minX
        let sy = primaryHeight - screen.frame.maxY
        return CGRect(x: sx, y: sy, width: screen.frame.width, height: screen.frame.height)
    }

    private func screen(forAxPoint point: CGPoint) -> NSScreen? {
        if let match = NSScreen.screens.first(where: { axScreenRect(for: $0).contains(point) }) {
            return match
        }
        let matchingX = NSScreen.screens.filter { screen in
            let rect = axScreenRect(for: screen)
            return point.x >= rect.minX && point.x <= rect.maxX
        }
        if matchingX.count == 1 {
            return matchingX.first
        }
        if matchingX.count > 1 {
            return matchingX.min(by: { abs(axScreenRect(for: $0).midY - point.y) < abs(axScreenRect(for: $1).midY - point.y) })
        }
        return NSScreen.main
    }
}
