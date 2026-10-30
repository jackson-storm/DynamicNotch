//
//  GlobalHotkeyManager.swift
//  DynamicNotch
//

import Carbon
import Foundation
internal import AppKit

final class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    enum HotkeyID: UInt32 {
        case localTimer = 1
        case toggleFloatingLyrics = 2
        case lyricsDelayLater = 3
        case lyricsDelayEarlier = 4
    }

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private var actions: [UInt32: () -> Void] = [:]

    private init() {
        installCarbonEventHandler()
    }

    func register(keyCode: UInt32, modifiers: NSEvent.ModifierFlags, action: @escaping () -> Void) {
        register(.localTimer, keyCode: keyCode, modifiers: modifiers, action: action)
    }

    func unregister() {
        unregister(.localTimer)
    }

    func register(
        _ id: HotkeyID,
        keyCode: UInt32,
        modifiers: NSEvent.ModifierFlags,
        action: @escaping () -> Void
    ) {
        unregister(id)
        actions[id.rawValue] = action

        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }

        let hotKeyID = EventHotKeyID(signature: OSType(0x444E544D), id: id.rawValue) // "DNTM"
        var hotKeyRef: EventHotKeyRef?
        RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        hotKeyRefs[id.rawValue] = hotKeyRef
    }

    func unregister(_ id: HotkeyID) {
        if let hotKeyRef = hotKeyRefs.removeValue(forKey: id.rawValue) {
            UnregisterEventHotKey(hotKeyRef)
        }
        actions[id.rawValue] = nil
    }

    private func installCarbonEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData, let event else { return noErr }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else { return status }

                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                let id = hotKeyID.id
                DispatchQueue.main.async {
                    manager.actions[id]?()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }
}
