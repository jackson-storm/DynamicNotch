//
//  WorkspacePlaybackSourceOpener.swift
//  DynamicNotch
//

internal import AppKit
import Foundation

@MainActor
protocol PlaybackSourceOpening: Sendable {
    func openPlaybackSource(_ source: NowPlayingPlaybackSource)
}

@MainActor
final class WorkspacePlaybackSourceOpener: PlaybackSourceOpening {
    func openPlaybackSource(_ source: NowPlayingPlaybackSource) {
        if let bundleIdentifier = source.preferredBundleIdentifier {
            if openApplication(bundleIdentifier: bundleIdentifier) {
                return
            }
        }

        if let processIdentifier = source.validProcessIdentifier,
           let application = NSRunningApplication(processIdentifier: pid_t(processIdentifier)) {
            showRunningApplication(application)
        }
    }

    private func openApplication(bundleIdentifier: String) -> Bool {
        if let existingApplication = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first {
            showRunningApplication(existingApplication)
            return true
        }

        guard let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return false
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration)
        return true
    }

    private func showRunningApplication(_ application: NSRunningApplication) {
        application.unhide()
        if #available(macOS 14.0, *) {
            application.activate()
        } else {
            _ = application.activate(options: [.activateIgnoringOtherApps])
        }
    }
}
