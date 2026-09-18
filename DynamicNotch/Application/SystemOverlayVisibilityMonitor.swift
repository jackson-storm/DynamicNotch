//
//  SystemOverlayVisibilityMonitor.swift
//  DynamicNotch
//
//  Created by Le Tien Dat on 9/19/26.
//

internal import AppKit
import ApplicationServices

@MainActor
final class SystemOverlayVisibilityMonitor {
    typealias VisibilityHandler = @MainActor (_ isVisible: Bool) -> Void

    private static let dockBundleIdentifier = "com.apple.dock"
    private static let dockOwnerName = "Dock"
    private static let dockSwipeSubtype = Int64(23)
    private static let verticalDockSwipeAxis = Int64(2)
    private static let eventFieldType = CGEventField(rawValue: 55)!
    private static let eventFieldHIDType = CGEventField(rawValue: 110)!
    private static let eventFieldSwipeAxis = CGEventField(rawValue: 123)!
    private static let eventFieldSwipeProgress = CGEventField(rawValue: 124)!
    private static let eventFieldPhase = CGEventField(rawValue: 132)!

    private let handler: VisibilityHandler
    private var monitorTask: Task<Void, Never>?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var lastVisible = false
    private var transientVisibleUntil: Date = .distantPast

    init(handler: @escaping VisibilityHandler) {
        self.handler = handler
    }

    func start() {
        guard monitorTask == nil else { return }

        installEventTap()

        monitorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(nanoseconds: 160_000_000)
            }
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
        removeEventTap()
    }

    private func refresh() {
        let isOverlayVisible = detectSystemOverlay()
        let isTransientVisible = transientVisibleUntil > Date()
        let isVisible = isOverlayVisible || isTransientVisible

        guard isVisible != lastVisible else { return }

        lastVisible = isVisible
        handler(isVisible)
    }

    private func recordDockSwipeEvent(
        axis: Int64,
        phase: Int64,
        progress: Double
    ) {
        guard axis == Self.verticalDockSwipeAxis else { return }

        if phase == 1 || phase == 2 {
            transientVisibleUntil = Date().addingTimeInterval(1.2)
            refresh()
        } else if phase == 4 || phase == 8 {
            transientVisibleUntil = Date().addingTimeInterval(0.25)
        }
    }

    private func detectSystemOverlay() -> Bool {
        if detectDockMissionControlWindow() {
            return true
        }

        if detectDockAccessibilityOverlay() {
            return true
        }

        return false
    }

    private func detectDockMissionControlWindow() -> Bool {
        guard
            let windowInfo = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
            ) as? [[String: Any]]
        else {
            return false
        }

        let displayBounds = displayBounds()

        for info in windowInfo {
            guard ownerName(from: info) == Self.dockOwnerName,
                alpha(from: info) > 0.01,
                let bounds = bounds(from: info)
            else {
                continue
            }

            let name = windowName(from: info)
            let layer = layer(from: info)

            for display in displayBounds where bounds.intersects(display) {
                if name.localizedCaseInsensitiveContains("Mission")
                    || name.localizedCaseInsensitiveContains("Expose")
                    || name.localizedCaseInsensitiveContains("Spaces")
                {
                    return true
                }

                if name.isEmpty,
                    layer == 18,
                    isFullDisplayWindow(bounds, on: display)
                {
                    return true
                }

                // Dock keeps an unnamed full-screen compositing window visible on Tahoe,
                // so empty-name geometry is not a reliable Mission Control signal.
            }
        }

        return false
    }

    private func detectDockAccessibilityOverlay() -> Bool {
        guard
            let dockApp = NSRunningApplication.runningApplications(
                withBundleIdentifier: Self.dockBundleIdentifier
            ).first
        else {
            return false
        }

        let appElement = AXUIElementCreateApplication(dockApp.processIdentifier)
        var visitedCount = 0
        return containsMissionControlElement(
            appElement,
            depth: 0,
            visitedCount: &visitedCount
        )
    }

    private func containsMissionControlElement(
        _ element: AXUIElement,
        depth: Int,
        visitedCount: inout Int
    ) -> Bool {
        guard depth <= 5, visitedCount < 700 else { return false }
        visitedCount += 1

        let role = stringAttribute(kAXRoleAttribute, from: element) ?? ""
        let title = stringAttribute(kAXTitleAttribute, from: element) ?? ""
        let identifier =
            stringAttribute(kAXIdentifierAttribute, from: element) ?? ""
        let description =
            stringAttribute(kAXDescriptionAttribute, from: element) ?? ""
        let value = stringAttribute(kAXValueAttribute, from: element) ?? ""
        let combined = [role, title, identifier, description, value]
            .joined(separator: " ")
            .lowercased()

        let looksLikeOverlay =
            combined.contains("spaces bar")
            || combined.contains("mission control")
            || combined.contains("expose")

        if looksLikeOverlay,
            role == kAXWindowRole || role == kAXGroupRole || role == kAXListRole
        {
            return true
        }

        let children: [AXUIElement] =
            axAttribute(kAXChildrenAttribute, from: element) ?? []
        for child in children {
            if containsMissionControlElement(
                child,
                depth: depth + 1,
                visitedCount: &visitedCount
            ) {
                return true
            }
        }

        return false
    }

    private func installEventTap() {
        guard eventTap == nil else { return }

        let eventMask =
            (CGEventMask(1) << 29) | (CGEventMask(1) << 30)
            | (CGEventMask(1) << 31)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput
            {
                let monitor = Unmanaged<SystemOverlayVisibilityMonitor>
                    .fromOpaque(userInfo)
                    .takeUnretainedValue()
                Task { @MainActor in
                    monitor.reenableEventTap()
                }
                return Unmanaged.passUnretained(event)
            }

            let rawType = event.getIntegerValueField(
                SystemOverlayVisibilityMonitor.eventFieldType
            )
            let hidType = event.getIntegerValueField(
                SystemOverlayVisibilityMonitor.eventFieldHIDType
            )
            guard rawType == 30,
                hidType == SystemOverlayVisibilityMonitor.dockSwipeSubtype
            else {
                return Unmanaged.passUnretained(event)
            }

            let axis = event.getIntegerValueField(
                SystemOverlayVisibilityMonitor.eventFieldSwipeAxis
            )
            let phase = event.getIntegerValueField(
                SystemOverlayVisibilityMonitor.eventFieldPhase
            )
            let progress = event.getDoubleValueField(
                SystemOverlayVisibilityMonitor.eventFieldSwipeProgress
            )
            let monitor = Unmanaged<SystemOverlayVisibilityMonitor>
                .fromOpaque(userInfo)
                .takeUnretainedValue()

            Task { @MainActor in
                monitor.recordDockSwipeEvent(
                    axis: axis,
                    phase: phase,
                    progress: progress
                )
            }

            return Unmanaged.passUnretained(event)
        }

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: eventMask,
                callback: callback,
                userInfo: userInfo
            )
        else {
            return
        }

        eventTap = tap
        eventTapSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            tap,
            0
        )
        if let eventTapSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func reenableEventTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    private func removeEventTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let eventTapSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                eventTapSource,
                .commonModes
            )
        }
        eventTapSource = nil
        eventTap = nil
    }

    private func displayBounds() -> [CGRect] {
        let bounds = NSScreen.screens.compactMap { screen -> CGRect? in
            let key = NSDeviceDescriptionKey("NSScreenNumber")
            guard let displayID = screen.deviceDescription[key] as? NSNumber
            else {
                return nil
            }

            return CGDisplayBounds(CGDirectDisplayID(displayID.uint32Value))
        }

        return bounds.isEmpty ? [CGDisplayBounds(CGMainDisplayID())] : bounds
    }

    private func ownerName(from info: [String: Any]) -> String? {
        info[kCGWindowOwnerName as String] as? String
    }

    private func windowName(from info: [String: Any]) -> String {
        info[kCGWindowName as String] as? String ?? ""
    }

    private func layer(from info: [String: Any]) -> Int {
        (info[kCGWindowLayer as String] as? NSNumber)?.intValue ?? 0
    }

    private func alpha(from info: [String: Any]) -> CGFloat {
        guard let alpha = info[kCGWindowAlpha as String] as? NSNumber else {
            return 1
        }

        return CGFloat(alpha.doubleValue)
    }

    private func bounds(from info: [String: Any]) -> CGRect? {
        guard let bounds = info[kCGWindowBounds as String] as? [String: Any]
        else {
            return nil
        }

        return CGRect(dictionaryRepresentation: bounds as CFDictionary)
    }

    private func isFullDisplayWindow(_ bounds: CGRect, on display: CGRect)
        -> Bool
    {
        abs(bounds.minX - display.minX) <= 2
            && abs(bounds.minY - display.minY) <= 2
            && abs(bounds.width - display.width) <= 4
            && abs(bounds.height - display.height) <= 4
    }

    private func axAttribute<T>(_ attribute: String, from element: AXUIElement)
        -> T?
    {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            attribute as CFString,
            &value
        )
        guard result == .success else {
            return nil
        }

        return value as? T
    }

    private func stringAttribute(_ attribute: String, from element: AXUIElement)
        -> String?
    {
        if let value: String = axAttribute(attribute, from: element) {
            return value
        }

        if let value: NSNumber = axAttribute(attribute, from: element) {
            return value.stringValue
        }

        return nil
    }

}
