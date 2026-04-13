import Combine
import CoreBluetooth
import Foundation
internal import AppKit
import SwiftUI

#if canImport(ApplicationServices)
import ApplicationServices
#endif

enum Kind: String {
    case accessibility
    case bluetooth
    case mediaControls
    case screenRecording
}

struct PermissionItem: Identifiable {
    let kind: Kind
    let titleKey: String
    let fallbackTitle: String
    let descriptionKey: String
    let fallbackDescription: String
    let assetImageName: String?
    let systemImage: String
    let tintColor: Color
    let isGranted: Bool
    let actionTitleKey: String?
    let fallbackActionTitle: String?
    let accessibilityIdentifier: String

    var id: String { kind.rawValue }
}

@MainActor
final class SettingsPermissionController: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published private(set) var isAccessibilityTrusted: Bool
    @Published private(set) var bluetoothAuthorization: CBManagerAuthorization
    @Published private(set) var canPostMediaKeyEvents: Bool
    @Published private(set) var canCaptureScreenAudio: Bool

    private var didPromptForAccessibility = false
    private var didPromptForPostEventAccess = false
    private var didPromptForScreenCaptureAccess = false
    private var bluetoothPermissionRequester: CBCentralManager?
    private var cancellables = Set<AnyCancellable>()

    private static let privacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )
    private static let bluetoothPrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth"
    )
    private static let screenCapturePrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    )

    init(notificationCenter: NotificationCenter = .default) {
        self.bluetoothAuthorization = Self.currentBluetoothAuthorizationStatus()
        self.isAccessibilityTrusted = Self.currentAccessibilityTrustState()
        self.canPostMediaKeyEvents = Self.currentPostEventAccessState()
        self.canCaptureScreenAudio = Self.currentScreenCaptureAccessState()

        super.init()

        notificationCenter.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        bluetoothAuthorization = Self.currentBluetoothAuthorizationStatus()
        isAccessibilityTrusted = Self.currentAccessibilityTrustState()
        canPostMediaKeyEvents = Self.currentPostEventAccessState()
        canCaptureScreenAudio = Self.currentScreenCaptureAccessState()
    }

    var permissionItems: [PermissionItem] {
        [
            PermissionItem(
                kind: .accessibility,
                titleKey: "settings.permissions.accessibility.title",
                fallbackTitle: "Accessibility",
                descriptionKey: "settings.permissions.accessibility.description",
                fallbackDescription: "Allow Accessibility access to use custom volume and brightness HUD controls.",
                assetImageName: nil,
                systemImage: "hand.raised.fill",
                tintColor: .orange,
                isGranted: isAccessibilityTrusted,
                actionTitleKey: isAccessibilityTrusted ? nil : (
                    didPromptForAccessibility ?
                    "settings.permissions.action.openPrivacySettings" :
                    "settings.permissions.action.grantAccess"
                ),
                fallbackActionTitle: isAccessibilityTrusted ? nil : (
                    didPromptForAccessibility ? "Open Privacy Settings" : "Grant Access"
                ),
                accessibilityIdentifier: "settings.permissions.accessibility"
            ),
            PermissionItem(
                kind: .bluetooth,
                titleKey: "settings.permissions.bluetooth.title",
                fallbackTitle: "Bluetooth",
                descriptionKey: "settings.permissions.bluetooth.description",
                fallbackDescription: "Allow Bluetooth access to read battery levels from supported accessories.",
                assetImageName: "bluetooth.white",
                systemImage: "dot.radiowaves.left.and.right",
                tintColor: .blue,
                isGranted: bluetoothAuthorization == .allowedAlways,
                actionTitleKey: bluetoothActionTitleKey,
                fallbackActionTitle: bluetoothFallbackActionTitle,
                accessibilityIdentifier: "settings.permissions.bluetooth"
            ),
            PermissionItem(
                kind: .mediaControls,
                titleKey: "settings.permissions.mediaControls.title",
                fallbackTitle: "Media Controls",
                descriptionKey: "settings.permissions.mediaControls.description",
                fallbackDescription: "Allow media control event access so play, pause, and track buttons work from Now Playing.",
                assetImageName: nil,
                systemImage: "music.note",
                tintColor: .pink,
                isGranted: canPostMediaKeyEvents,
                actionTitleKey: canPostMediaKeyEvents ? nil : (
                    didPromptForPostEventAccess ?
                    "settings.permissions.action.openPrivacySettings" :
                    "settings.permissions.action.grantAccess"
                ),
                fallbackActionTitle: canPostMediaKeyEvents ? nil : (
                    didPromptForPostEventAccess ? "Open Privacy Settings" : "Grant Access"
                ),
                accessibilityIdentifier: "settings.permissions.mediaControls"
            ),
            PermissionItem(
                kind: .screenRecording,
                titleKey: "settings.permissions.screenRecording.title",
                fallbackTitle: "Screen Recording",
                descriptionKey: "settings.permissions.screenRecording.description",
                fallbackDescription: "Allow Screen Recording access so the audio-reactive Now Playing equalizer can listen to system audio.",
                assetImageName: nil,
                systemImage: "record.circle",
                tintColor: .red,
                isGranted: canCaptureScreenAudio,
                actionTitleKey: canCaptureScreenAudio ? nil : (
                    didPromptForScreenCaptureAccess ?
                    "settings.permissions.action.openPrivacySettings" :
                    "settings.permissions.action.grantAccess"
                ),
                fallbackActionTitle: canCaptureScreenAudio ? nil : (
                    didPromptForScreenCaptureAccess ? "Open Privacy Settings" : "Grant Access"
                ),
                accessibilityIdentifier: "settings.permissions.screenRecording"
            )
        ]
    }

    func performAction(for kind: Kind) {
        switch kind {
        case .accessibility:
            requestAccessibilityAccess()
        case .bluetooth:
            requestBluetoothAccess()
        case .mediaControls:
            requestPostEventAccess()
        case .screenRecording:
            requestScreenCaptureAccess()
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        refresh()
    }

    private func requestAccessibilityAccess() {
        guard !Self.currentAccessibilityTrustState() else {
            refresh()
            return
        }

        if !didPromptForAccessibility {
            didPromptForAccessibility = true

            #if canImport(ApplicationServices)
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            #endif
        } else {
            Self.openPrivacySettings()
        }

        refresh()
    }

    private func requestPostEventAccess() {
        guard !Self.currentPostEventAccessState() else {
            refresh()
            return
        }

        if !didPromptForPostEventAccess {
            didPromptForPostEventAccess = true

            #if canImport(ApplicationServices)
            _ = CGRequestPostEventAccess()
            #endif
        } else {
            Self.openPrivacySettings()
        }

        refresh()
    }

    private func requestScreenCaptureAccess() {
        guard !Self.currentScreenCaptureAccessState() else {
            refresh()
            return
        }

        if !didPromptForScreenCaptureAccess {
            didPromptForScreenCaptureAccess = true

            #if canImport(ApplicationServices)
            _ = CGRequestScreenCaptureAccess()
            #endif
        } else {
            Self.openScreenCapturePrivacySettings()
        }

        refresh()
    }

    private var bluetoothActionTitleKey: String? {
        switch bluetoothAuthorization {
        case .allowedAlways:
            return nil
        case .notDetermined:
            return "settings.permissions.action.grantAccess"
        case .restricted, .denied:
            return "settings.permissions.action.openPrivacySettings"
        @unknown default:
            return "settings.permissions.action.openPrivacySettings"
        }
    }

    private var bluetoothFallbackActionTitle: String? {
        switch bluetoothAuthorization {
            case .allowedAlways:
                return nil
            case .notDetermined:
                return "Grant Access"
            case .restricted, .denied:
                return "Open Privacy Settings"
            @unknown default:
                return "Open Privacy Settings"
        }
    }

    private func requestBluetoothAccess() {
        switch Self.currentBluetoothAuthorizationStatus() {
        case .allowedAlways:
            refresh()
        case .notDetermined:
            if bluetoothPermissionRequester == nil {
                bluetoothPermissionRequester = CBCentralManager(
                    delegate: self,
                    queue: nil,
                    options: [CBCentralManagerOptionShowPowerAlertKey: false]
                )
            }
        case .restricted, .denied:
            Self.openBluetoothPrivacySettings()
        @unknown default:
            Self.openBluetoothPrivacySettings()
        }
    }

    private static func openPrivacySettings() {
        guard let privacySettingsURL else { return }
        NSWorkspace.shared.open(privacySettingsURL)
    }

    private static func openBluetoothPrivacySettings() {
        guard let bluetoothPrivacySettingsURL else { return }
        NSWorkspace.shared.open(bluetoothPrivacySettingsURL)
    }

    private static func openScreenCapturePrivacySettings() {
        guard let screenCapturePrivacySettingsURL else { return }
        NSWorkspace.shared.open(screenCapturePrivacySettingsURL)
    }

    private static func currentAccessibilityTrustState() -> Bool {
        #if canImport(ApplicationServices)
        AXIsProcessTrusted()
        #else
        true
        #endif
    }

    private static func currentPostEventAccessState() -> Bool {
        #if canImport(ApplicationServices)
        CGPreflightPostEventAccess()
        #else
        true
        #endif
    }

    private static func currentScreenCaptureAccessState() -> Bool {
        #if canImport(ApplicationServices)
        CGPreflightScreenCaptureAccess()
        #else
        true
        #endif
    }

    private static func currentBluetoothAuthorizationStatus() -> CBManagerAuthorization {
        CBManager.authorization
    }
}
