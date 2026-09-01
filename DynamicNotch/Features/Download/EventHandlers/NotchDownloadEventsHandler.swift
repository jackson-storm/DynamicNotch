//
//  NotchDownloadEventsHandler.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/14/26.
//

import SwiftUI

@MainActor
final class NotchDownloadEventsHandler {
    private let notchViewModel: NotchViewModel
    private let downloadViewModel: DownloadViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        downloadViewModel: DownloadViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.downloadViewModel = downloadViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handleDownload(_ event: DownloadEvent) {
        switch event {
        case .started:
            guard settingsViewModel.isLiveActivityEnabled(.downloads) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    DownloadNotchContent(
                        downloadViewModel: downloadViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.download.id))
        }
    }
}

