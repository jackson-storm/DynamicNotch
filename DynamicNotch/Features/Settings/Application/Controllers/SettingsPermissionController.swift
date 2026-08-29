import Combine
import Contacts
import CoreBluetooth
import Foundation
internal import AppKit
import SwiftUI
import AVFoundation
internal import EventKit

#if canImport(ApplicationServices)
import ApplicationServices
import CoreServices
#endif

enum Kind: String {
    case accessibility
    case bluetooth
    case mediaControls
    case camera
    case contacts
    case calendar
    case fullDiskAccess
    case automation
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
    let iconColor: Color
    let isGranted: Bool
    let actionTitleKey: String?
    let fallbackActionTitle: String?
    let accessibilityIdentifier: String

    init(
        kind: Kind,
        titleKey: String,
        fallbackTitle: String,
        descriptionKey: String,
        fallbackDescription: String,
        assetImageName: String? = nil,
        systemImage: String,
        tintColor: Color,
        iconColor: Color = .white,
        isGranted: Bool,
        actionTitleKey: String?,
        fallbackActionTitle: String?,
        accessibilityIdentifier: String
    ) {
        self.kind = kind
        self.titleKey = titleKey
        self.fallbackTitle = fallbackTitle
        self.descriptionKey = descriptionKey
        self.fallbackDescription = fallbackDescription
        self.assetImageName = assetImageName
        self.systemImage = systemImage
        self.tintColor = tintColor
        self.iconColor = iconColor
        self.isGranted = isGranted
        self.actionTitleKey = actionTitleKey
        self.fallbackActionTitle = fallbackActionTitle
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var id: String { kind.rawValue }
}

@MainActor
final class SettingsPermissionController: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published private(set) var isAccessibilityTrusted: Bool
    @Published private(set) var bluetoothAuthorization: CBManagerAuthorization
    @Published private(set) var canPostMediaKeyEvents: Bool
    @Published private(set) var cameraAuthorization: AVAuthorizationStatus
    @Published private(set) var contactsAuthorization: CNAuthorizationStatus
    @Published private(set) var calendarAuthorization: EKAuthorizationStatus
    @Published private(set) var isFullDiskAccessGranted: Bool
    @Published private(set) var isAutomationAccessGranted: Bool

    private var didPromptForAccessibility = false
    private var didPromptForPostEventAccess = false
    private var didPromptForCameraAccess = false
    private var didPromptForCalendarAccess = false
    private var didPromptForAutomationAccess = false
    private var bluetoothPermissionRequester: CBCentralManager?
    private let contactsStore = CNContactStore()
    private var cancellables = Set<AnyCancellable>()

    private static let privacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )
    private static let bluetoothPrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth"
    )
    private static let cameraPrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
    )
    private static let contactsPrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts"
    )
    private static let calendarPrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
    )
    private static let fullDiskAccessPrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    )
    private static let automationPrivacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
    )

    init(notificationCenter: NotificationCenter = .default) {
        self.bluetoothAuthorization = Self.currentBluetoothAuthorizationStatus()
        self.isAccessibilityTrusted = Self.currentAccessibilityTrustState()
        self.canPostMediaKeyEvents = Self.currentPostEventAccessState()
        self.cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
        self.contactsAuthorization = CNContactStore.authorizationStatus(for: .contacts)
        self.calendarAuthorization = EKEventStore.authorizationStatus(for: .event)
        self.isFullDiskAccessGranted = FullDiskAccessAuthorization.hasPermission()
        self.isAutomationAccessGranted = Self.currentAutomationAccessState()

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
        cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
        contactsAuthorization = CNContactStore.authorizationStatus(for: .contacts)
        calendarAuthorization = EKEventStore.authorizationStatus(for: .event)
        isFullDiskAccessGranted = FullDiskAccessAuthorization.hasPermission()
        isAutomationAccessGranted = Self.currentAutomationAccessState()
    }

    var permissionItems: [PermissionItem] {
        [
            PermissionItem(
                kind: .accessibility,
                titleKey: "settings.permissions.accessibility.title",
                fallbackTitle: "Accessibility",
                descriptionKey: "settings.permissions.accessibility.description",
                fallbackDescription: "Allow Accessibility access to use custom volume and brightness HUD controls.",
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
                kind: .camera,
                titleKey: "settings.permissions.camera.title",
                fallbackTitle: "Camera",
                descriptionKey: "settings.permissions.camera.description",
                fallbackDescription: "Allow Camera access to display a camera preview in the notch.",
                assetImageName: nil,
                systemImage: "camera.fill",
                tintColor: .gray,
                iconColor: .black,
                isGranted: cameraAuthorization == .authorized,
                actionTitleKey: cameraActionTitleKey,
                fallbackActionTitle: cameraFallbackActionTitle,
                accessibilityIdentifier: "settings.permissions.camera"
            ),
            PermissionItem(
                kind: .contacts,
                titleKey: "settings.permissions.contacts.title",
                fallbackTitle: "Contacts",
                descriptionKey: "settings.permissions.contacts.description",
                fallbackDescription: "Allow Contacts access to show sender names and photos in Messages notifications.",
                assetImageName: nil,
                systemImage: "person.crop.circle.fill",
                tintColor: .blue,
                isGranted: contactsAuthorization == .authorized,
                actionTitleKey: contactsActionTitleKey,
                fallbackActionTitle: contactsFallbackActionTitle,
                accessibilityIdentifier: "settings.permissions.contacts"
            ),
            PermissionItem(
                kind: .mediaControls,
                titleKey: "settings.permissions.mediaControls.title",
                fallbackTitle: "Media Controls",
                descriptionKey: "settings.permissions.mediaControls.description",
                fallbackDescription: "Allow media control event access so play, pause, and track buttons work from Now Playing.",
                systemImage: "music.note",
                tintColor: .red,
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
                kind: .fullDiskAccess,
                titleKey: "settings.permissions.fullDiskAccess.title",
                fallbackTitle: "Full Disk Access",
                descriptionKey: "settings.permissions.fullDiskAccess.description",
                fallbackDescription: "Allow Full Disk Access to display real names and custom icons of Focus modes.",
                systemImage: "opticaldiscdrive.fill",
                tintColor: .gray,
                isGranted: isFullDiskAccessGranted,
                actionTitleKey: isFullDiskAccessGranted ? nil : "settings.permissions.action.openPrivacySettings",
                fallbackActionTitle: isFullDiskAccessGranted ? nil : "Open Privacy Settings",
                accessibilityIdentifier: "settings.permissions.fullDiskAccess"
            ),
            PermissionItem(
                kind: .calendar,
                titleKey: "settings.permissions.calendar.title",
                fallbackTitle: "Calendar",
                descriptionKey: "settings.permissions.calendar.description",
                fallbackDescription: "Allow Calendar access to display your upcoming events.",
                assetImageName: nil,
                systemImage: "calendar",
                tintColor: .blue,
                isGranted: calendarAuthorization == .fullAccess,
                actionTitleKey: calendarActionTitleKey,
                fallbackActionTitle: calendarFallbackActionTitle,
                accessibilityIdentifier: "settings.permissions.calendar"
            ),
            PermissionItem(
                kind: .automation,
                titleKey: "settings.permissions.automation.title",
                fallbackTitle: "Automation (System Events)",
                descriptionKey: "settings.permissions.automation.description",
                fallbackDescription: "Allow Full Disk Access to display Mail notifications and real names and custom icons of Focus modes.",
                assetImageName: nil,
                systemImage: "gearshape.2.fill",
                tintColor: .gray,
                isGranted: isAutomationAccessGranted,
                actionTitleKey: isAutomationAccessGranted ? nil : (
                    didPromptForAutomationAccess ?
                    "settings.permissions.action.openPrivacySettings" :
                    "settings.permissions.action.grantAccess"
                ),
                fallbackActionTitle: isAutomationAccessGranted ? nil : (
                    didPromptForAutomationAccess ? "Open Privacy Settings" : "Grant Access"
                ),
                accessibilityIdentifier: "settings.permissions.automation"
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
        case .camera:
            requestCameraAccess()
        case .contacts:
            requestContactsAccess()
        case .calendar:
            requestCalendarAccess()
        case .fullDiskAccess:
            Self.openFullDiskAccessPrivacySettings()
        case .automation:
            requestAutomationAccess()
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

    private var cameraActionTitleKey: String? {
        switch cameraAuthorization {
        case .authorized:
            return nil
        case .notDetermined:
            return "settings.permissions.action.grantAccess"
        case .restricted, .denied:
            return "settings.permissions.action.openPrivacySettings"
        @unknown default:
            return "settings.permissions.action.openPrivacySettings"
        }
    }

    private var cameraFallbackActionTitle: String? {
        switch cameraAuthorization {
        case .authorized:
            return nil
        case .notDetermined:
            return "Grant Access"
        case .restricted, .denied:
            return "Open Privacy Settings"
        @unknown default:
            return "Open Privacy Settings"
        }
    }

    private var contactsActionTitleKey: String? {
        switch contactsAuthorization {
        case .authorized:
            return nil
        case .notDetermined:
            return "settings.permissions.action.grantAccess"
        case .restricted, .denied:
            return "settings.permissions.action.openPrivacySettings"
        @unknown default:
            return "settings.permissions.action.openPrivacySettings"
        }
    }

    private var contactsFallbackActionTitle: String? {
        switch contactsAuthorization {
        case .authorized:
            return nil
        case .notDetermined:
            return "Grant Access"
        case .restricted, .denied:
            return "Open Privacy Settings"
        @unknown default:
            return "Open Privacy Settings"
        }
    }

    private var calendarActionTitleKey: String? {
        switch calendarAuthorization {
        case .fullAccess, .writeOnly:
            return nil
        case .notDetermined:
            return "settings.permissions.action.grantAccess"
        case .restricted, .denied:
            return "settings.permissions.action.openPrivacySettings"
        @unknown default:
            return "settings.permissions.action.openPrivacySettings"
        }
    }

    private var calendarFallbackActionTitle: String? {
        switch calendarAuthorization {
        case .fullAccess, .writeOnly:
            return nil
        case .notDetermined:
            return "Grant Access"
        case .restricted, .denied:
            return "Open Privacy Settings"
        @unknown default:
            return "Open Privacy Settings"
        }
    }

    private func requestCameraAccess() {
        switch cameraAuthorization {
        case .authorized:
            refresh()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refresh()
                }
            }
        case .restricted, .denied:
            Self.openCameraPrivacySettings()
        @unknown default:
            Self.openCameraPrivacySettings()
        }
    }

    private func requestContactsAccess() {
        switch contactsAuthorization {
        case .authorized:
            Self.openContactsPrivacySettings()
        case .notDetermined:
            contactsStore.requestAccess(for: .contacts) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.refresh()
                }
            }
        case .restricted, .denied:
            Self.openContactsPrivacySettings()
        @unknown default:
            Self.openContactsPrivacySettings()
        }
    }

    private func requestCalendarAccess() {
        switch calendarAuthorization {
        case .fullAccess, .writeOnly:
            refresh()
        case .notDetermined:
            let store = EKEventStore()
            if #available(macOS 14.0, *) {
                store.requestFullAccessToEvents { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.refresh()
                    }
                }
            } else {
                store.requestAccess(to: .event) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.refresh()
                    }
                }
            }
        case .restricted, .denied:
            Self.openCalendarPrivacySettings()
        @unknown default:
            Self.openCalendarPrivacySettings()
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

    private static func openContactsPrivacySettings() {
        guard let contactsPrivacySettingsURL else { return }
        NSWorkspace.shared.open(contactsPrivacySettingsURL)
    }

    private static func openCameraPrivacySettings() {
        guard let cameraPrivacySettingsURL else { return }
        NSWorkspace.shared.open(cameraPrivacySettingsURL)
    }

    private static func openCalendarPrivacySettings() {
        guard let calendarPrivacySettingsURL else { return }
        NSWorkspace.shared.open(calendarPrivacySettingsURL)
    }

    private static func openFullDiskAccessPrivacySettings() {
        guard let fullDiskAccessPrivacySettingsURL else { return }
        NSWorkspace.shared.open(fullDiskAccessPrivacySettingsURL)
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

    private func requestAutomationAccess() {
        guard !Self.currentAutomationAccessState() else {
            refresh()
            return
        }

        if !didPromptForAutomationAccess {
            didPromptForAutomationAccess = true
            let script = "tell application \"System Events\" to get name"
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                _ = appleScript.executeAndReturnError(&error)
            }
        } else {
            Self.openAutomationPrivacySettings()
        }

        refresh()
    }

    private static func openAutomationPrivacySettings() {
        guard let automationPrivacySettingsURL else { return }
        NSWorkspace.shared.open(automationPrivacySettingsURL)
    }

    private static func currentAutomationAccessState() -> Bool {
        let script = "tell application \"System Events\" to get name"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            _ = appleScript.executeAndReturnError(&error)
            if let err = error, let errNum = err[NSAppleScript.errorNumber] as? Int, errNum == -1743 || errNum == -1744 {
                return false
            }
        }
        return true
    }

    private static func currentBluetoothAuthorizationStatus() -> CBManagerAuthorization {
        CBManager.authorization
    }
}
