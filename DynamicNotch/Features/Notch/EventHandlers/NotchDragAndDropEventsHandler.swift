//
//  NotchDragAndDropEventsHandler.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/14/26.
//

import SwiftUI

@MainActor
final class NotchDragAndDropEventsHandler {
    private let notchViewModel: NotchViewModel
    private let airDropViewModel: AirDropNotchViewModel
    private let settingsViewModel: SettingsViewModel
    
    init(
        notchViewModel: NotchViewModel,
        airDropViewModel: AirDropNotchViewModel,
        settingsViewModel: SettingsViewModel,
    ) {
        self.notchViewModel = notchViewModel
        self.airDropViewModel = airDropViewModel
        self.settingsViewModel = settingsViewModel
    }
    
    func handleAirDrop(_ event: AirDropEvent) {
        switch event {
        case .dragStarted:
            guard settingsViewModel.isLiveActivityEnabled(.drop) else { return }
            hideInactiveDragAndDropActivities()
            showDragAndDropLiveActivity()
            
        case .dragEnded, .dropped:
            hideDragAndDropActivities()
        }
    }
    
    func refreshDragAndDropPresentation() {
        hideDragAndDropActivities()
        guard airDropViewModel.isDraggingFile else { return }
        handleAirDrop(.dragStarted)
    }
    
    private func showDragAndDropLiveActivity() {
        let isAirDropEnabled = settingsViewModel.mediaAndFiles.isAirDropLiveActivityEnabled
        let isTrayEnabled = settingsViewModel.mediaAndFiles.isTrayLiveActivityEnabled

        switch settingsViewModel.mediaAndFiles.dragAndDropActivityMode {
        case .airDrop:
            guard isAirDropEnabled else { return }
            notchViewModel.send(
                .showLiveActivity(
                    AirDropNotchContent(
                        airDropViewModel: airDropViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )
            
        case .tray:
            guard isTrayEnabled else { return }
            notchViewModel.send(
                .showLiveActivity(
                    TrayNotchContent(
                        airDropViewModel: airDropViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )
            
        case .combined:
            if isAirDropEnabled && isTrayEnabled {
                notchViewModel.send(
                    .showLiveActivity(
                        DragAndDropCombinedNotchContent(
                            airDropViewModel: airDropViewModel,
                            settingsViewModel: settingsViewModel
                        )
                    )
                )
            } else if isAirDropEnabled {
                notchViewModel.send(
                    .showLiveActivity(
                        AirDropNotchContent(
                            airDropViewModel: airDropViewModel,
                            settingsViewModel: settingsViewModel
                        )
                    )
                )
            } else if isTrayEnabled {
                notchViewModel.send(
                    .showLiveActivity(
                        TrayNotchContent(
                            airDropViewModel: airDropViewModel,
                            settingsViewModel: settingsViewModel
                        )
                    )
                )
            }
        }
    }
    
    private func hideDragAndDropActivities() {
        NotchContentRegistry.DragAndDrop.liveActivityIDs.forEach { id in
            notchViewModel.send(.hideLiveActivity(id: id))
        }
    }
    
    private func hideInactiveDragAndDropActivities() {
        let activeID: String
        
        switch settingsViewModel.mediaAndFiles.dragAndDropActivityMode {
        case .airDrop:
            activeID = NotchContentRegistry.DragAndDrop.airDrop.id
        case .tray:
            activeID = NotchContentRegistry.DragAndDrop.tray.id
        case .combined:
            activeID = NotchContentRegistry.DragAndDrop.combined.id
        }
        
        NotchContentRegistry.DragAndDrop.liveActivityIDs
            .filter { $0 != activeID }
            .forEach { id in
                notchViewModel.send(.hideLiveActivity(id: id))
            }
    }
}
