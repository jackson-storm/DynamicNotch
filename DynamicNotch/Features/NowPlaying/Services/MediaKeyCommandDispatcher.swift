import Foundation
internal import AppKit

final class MediaKeyCommandDispatcher {
    private enum MediaKeyCode: Int32 {
        case playPause = 16
        case nextTrack = 17
        case previousTrack = 18
    }

    private let privacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )
    private var didPromptForEventAccess = false
    private var didOpenPrivacySettings = false

    func send(_ command: NowPlayingCommand) {
        guard ensureEventSynthesizingAccess() else { return }

        let keyCode: MediaKeyCode

        switch command {
        case .togglePlayPause:
            keyCode = .playPause
        case .nextTrack:
            keyCode = .nextTrack
        case .previousTrack:
            keyCode = .previousTrack
        case .play, .pause, .seek, .setShuffle, .setRepeatMode, .setVolume, .setFavorite:
            return
        }

        postMediaKeyEvent(keyCode, isKeyDown: true)
        postMediaKeyEvent(keyCode, isKeyDown: false)
    }

    private func ensureEventSynthesizingAccess() -> Bool {
        if CGPreflightPostEventAccess() {
            return true
        }

        if !didPromptForEventAccess {
            didPromptForEventAccess = true

            if CGRequestPostEventAccess() {
                return true
            }
        }

        guard !CGPreflightPostEventAccess() else {
            return true
        }

        if !didOpenPrivacySettings, let privacySettingsURL {
            didOpenPrivacySettings = true
            NSWorkspace.shared.open(privacySettingsURL)
        }

        return false
    }

    private func postMediaKeyEvent(_ keyCode: MediaKeyCode, isKeyDown: Bool) {
        let flags = NSEvent.ModifierFlags(rawValue: isKeyDown ? 0xA00 : 0xB00)
        let keyState = isKeyDown ? 0xA : 0xB
        let data1 = Int((keyCode.rawValue << 16) | Int32(keyState << 8))

        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: flags,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: -1
        ) else {
            return
        }

        event.cgEvent?.post(tap: .cghidEventTap)
    }
}
