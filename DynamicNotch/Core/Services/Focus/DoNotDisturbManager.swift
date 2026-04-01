import Foundation
import SwiftUI
import Combine
internal import AppKit

final class DoNotDisturbManager: ObservableObject {
    static let shared = DoNotDisturbManager()

    @Published private(set) var isMonitoring = false
    @Published var isDoNotDisturbActive = false
    @Published var currentFocusModeName: String = ""
    @Published var currentFocusModeIdentifier: String = ""

    private let notificationCenter = DistributedNotificationCenter.default()
    private let metadataExtractionQueue = DispatchQueue(
        label: "com.dynamicisland.focus.metadata",
        qos: .userInitiated
    )
    let focusLogStream = FocusLogStream()

    private init() {
        focusLogStream.onMetadataUpdate = { [weak self] identifier, name in
            self?.handleLogMetadataUpdate(identifier: identifier, name: name)
        }
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        notificationCenter.addObserver(
            self,
            selector: #selector(handleFocusEnabled(_:)),
            name: .focusModeEnabled,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleFocusDisabled(_:)),
            name: .focusModeDisabled,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )

        focusLogStream.start()
        isMonitoring = true
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        notificationCenter.removeObserver(self, name: .focusModeEnabled, object: nil)
        notificationCenter.removeObserver(self, name: .focusModeDisabled, object: nil)

        focusLogStream.stop()
        isMonitoring = false

        DispatchQueue.main.async {
            self.isDoNotDisturbActive = false
            self.currentFocusModeIdentifier = ""
            self.currentFocusModeName = ""
        }
    }

    @objc private func handleFocusEnabled(_ notification: Notification) {
        apply(notification: notification, isActive: true)
    }

    @objc private func handleFocusDisabled(_ notification: Notification) {
        apply(notification: notification, isActive: false)
    }

    private func apply(notification: Notification, isActive: Bool) {
        metadataExtractionQueue.async { [weak self] in
            guard let self else { return }

            let metadata = self.extractMetadata(from: notification)
            self.publishMetadata(
                identifier: metadata.identifier,
                name: metadata.name,
                isActive: isActive,
                source: notification.name.rawValue
            )
        }
    }

    private func publishMetadata(
        identifier: String?,
        name: String?,
        isActive: Bool?,
        source: String
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let trimmedIdentifier = identifier?.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedMode = FocusModeType.resolve(identifier: trimmedIdentifier, name: trimmedName)

            let finalIdentifier: String
            if let identifier = trimmedIdentifier, !identifier.isEmpty {
                finalIdentifier = identifier
            } else {
                finalIdentifier = resolvedMode.rawValue
            }

            let finalName: String
            if let name = trimmedName, !name.isEmpty {
                finalName = name
            } else if !resolvedMode.displayName.isEmpty {
                finalName = resolvedMode.displayName
            } else if let identifier = trimmedIdentifier, !identifier.isEmpty {
                finalName = identifier
            } else {
                finalName = "Focus"
            }

            let previousIdentifier = self.currentFocusModeIdentifier
            let previousName = self.currentFocusModeName
            let previousActive = self.isDoNotDisturbActive

            let identifierChanged = finalIdentifier != previousIdentifier
            let nameChanged = finalName != previousName
            let shouldToggleActive = isActive.map { $0 != previousActive } ?? false

            if identifierChanged {
                self.currentFocusModeIdentifier = finalIdentifier
            }

            if nameChanged {
                self.currentFocusModeName = finalName.localizedCaseInsensitiveContains(
                    "Reduce Interruptions"
                ) ? "Reduce Interr." : finalName
            }

            if identifierChanged || nameChanged || shouldToggleActive {
                debugPrint(
                    "[DoNotDisturbManager] Focus update -> source: \(source) | identifier: \(trimmedIdentifier ?? "<nil>") | name: \(trimmedName ?? "<nil>") | resolved: \(resolvedMode.rawValue)"
                )
            }

            guard let isActive, shouldToggleActive else { return }

            withAnimation(.smooth(duration: 0.25)) {
                self.isDoNotDisturbActive = isActive
            }
        }
    }

    private func handleLogMetadataUpdate(identifier: String?, name: String?) {
        metadataExtractionQueue.async { [weak self] in
            guard let self else { return }

            let trimmedIdentifier = identifier?.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasIdentifier = trimmedIdentifier?.isEmpty == false
            let hasName = trimmedName?.isEmpty == false

            guard hasIdentifier || hasName else { return }

            self.publishMetadata(
                identifier: trimmedIdentifier,
                name: trimmedName,
                isActive: nil,
                source: "log-stream"
            )
        }
    }
}

private extension Notification.Name {
    static let focusModeEnabled = Notification.Name("_NSDoNotDisturbEnabledNotification")
    static let focusModeDisabled = Notification.Name("_NSDoNotDisturbDisabledNotification")
}
