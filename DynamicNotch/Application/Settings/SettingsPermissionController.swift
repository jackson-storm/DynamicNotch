import Combine
import Foundation
internal import AppKit

#if canImport(ApplicationServices)
import ApplicationServices
#endif

@MainActor
final class SettingsPermissionController: ObservableObject {
    struct ToolbarAction {
        let titleKey: String
        let fallbackTitle: String
        let systemImage: String
        let helpKey: String
        let fallbackHelp: String
        let accessibilityIdentifier: String
        let handler: () -> Void
    }

    @Published private(set) var isAccessibilityTrusted: Bool
    @Published private(set) var canPostMediaKeyEvents: Bool

    private var didPromptForAccessibility = false
    private var didPromptForPostEventAccess = false
    private var cancellables = Set<AnyCancellable>()

    private static let privacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )

    init(notificationCenter: NotificationCenter = .default) {
        self.isAccessibilityTrusted = Self.currentAccessibilityTrustState()
        self.canPostMediaKeyEvents = Self.currentPostEventAccessState()

        notificationCenter.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        isAccessibilityTrusted = Self.currentAccessibilityTrustState()
        canPostMediaKeyEvents = Self.currentPostEventAccessState()
    }

    func toolbarAction(for section: SettingsRootViewModel.Section) -> ToolbarAction? {
        switch section.permissionRequirement {
        case .accessibility:
            guard !isAccessibilityTrusted else { return nil }
            return ToolbarAction(
                titleKey: didPromptForAccessibility ?
                    "settings.toolbar.permission.accessibility.openSettings" :
                    "settings.toolbar.permission.accessibility.grant",
                fallbackTitle: didPromptForAccessibility ? "Open Privacy Settings" : "Grant Access",
                systemImage: didPromptForAccessibility ? "gear" : "hand.raised.fill",
                helpKey: didPromptForAccessibility ?
                    "settings.toolbar.permission.accessibility.openSettings.help" :
                    "settings.toolbar.permission.accessibility.grant.help",
                fallbackHelp: didPromptForAccessibility ?
                    "Open Privacy & Security to allow Accessibility access for custom HUD controls." :
                    "Grant Accessibility access to use custom volume and brightness HUD controls.",
                accessibilityIdentifier: "settings.toolbar.permission.accessibility"
            ) { [weak self] in
                self?.requestAccessibilityAccess()
            }

        case .postEventAccess:
            guard !canPostMediaKeyEvents else { return nil }
            return ToolbarAction(
                titleKey: didPromptForPostEventAccess ?
                    "settings.toolbar.permission.mediaControls.openSettings" :
                    "settings.toolbar.permission.mediaControls.grant",
                fallbackTitle: didPromptForPostEventAccess ? "Open Privacy Settings" : "Grant Access",
                systemImage: didPromptForPostEventAccess ? "gear" : "music.note",
                helpKey: didPromptForPostEventAccess ?
                    "settings.toolbar.permission.mediaControls.openSettings.help" :
                    "settings.toolbar.permission.mediaControls.grant.help",
                fallbackHelp: didPromptForPostEventAccess ?
                    "Open Privacy & Security to allow media control events for Now Playing actions." :
                    "Grant media control access so play, pause, and track buttons work from the notch.",
                accessibilityIdentifier: "settings.toolbar.permission.mediaControls"
            ) { [weak self] in
                self?.requestPostEventAccess()
            }

        case nil:
            return nil
        }
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

    private static func openPrivacySettings() {
        guard let privacySettingsURL else { return }
        NSWorkspace.shared.open(privacySettingsURL)
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
}
