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
            if ApplicationActivator.shared.openOrActivate(bundleIdentifier: bundleIdentifier) {
                return
            }
        }

        if let processIdentifier = source.validProcessIdentifier,
           let application = NSRunningApplication(processIdentifier: pid_t(processIdentifier)) {
            ApplicationActivator.shared.openOrActivate(application: application)
        }
    }
}
