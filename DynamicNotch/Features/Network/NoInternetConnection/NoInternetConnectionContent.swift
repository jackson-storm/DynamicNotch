//
//  NoInternetConnectionContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/30/26.
//

import SwiftUI
internal import AppKit

struct NoInternetConnectionContent: NotchContentProtocol {
    let id = NotchContentRegistry.Network.noInternet.id
    var priority: Int { NotchContentRegistry.Network.noInternet.priority }

    let onDismiss: @MainActor () -> Void
    let onOpenNetworkSettings: @MainActor () -> Void

    init(
        onDismiss: @escaping @MainActor () -> Void = {},
        onOpenNetworkSettings: @escaping @MainActor () -> Void = {
            Self.openNetworkSettings()
        }
    ) {
        self.onDismiss = onDismiss
        self.onOpenNetworkSettings = onOpenNetworkSettings
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 110, height: baseHeight + 120)
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }

    func makeView() -> AnyView {
        AnyView(
            NoInternetConnectionView(
                onDismiss: onDismiss,
                onOpenNetworkSettings: onOpenNetworkSettings
            )
        )
    }

    @MainActor
    private static func openNetworkSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.network") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
