//
//  NotchDragAndDropEventsHandler.swift
//  DynamicNotch
//

import SwiftUI
import Combine

@MainActor
final class NotchDragAndDropEventsHandler {
    private let notchViewModel: NotchViewModel
    private let airDropViewModel: AirDropNotchViewModel
    private let fileTrayViewModel: FileTrayViewModel
    private let settingsViewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    init(
        notchViewModel: NotchViewModel,
        airDropViewModel: AirDropNotchViewModel,
        fileTrayViewModel: FileTrayViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.airDropViewModel = airDropViewModel
        self.fileTrayViewModel = fileTrayViewModel
        self.settingsViewModel = settingsViewModel

        setupItemCallbacks()
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

    func syncAirDropTransferLiveActivity() {
        guard settingsViewModel.isLiveActivityEnabled(.drop),
              settingsViewModel.mediaAndFiles.isAirDropLiveActivityEnabled,
              airDropViewModel.activeTransfer != nil else {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.airDropTransferActive.id))
            return
        }

        notchViewModel.send(
            .showLiveActivity(
                AirDropActiveNotchContent(
                    airDropViewModel: airDropViewModel,
                    mediaSettings: settingsViewModel.mediaAndFiles
                )
            )
        )
    }

    func syncFileTrayLiveActivity(hasItems: Bool? = nil) {
        let hasTrayItems = hasItems ?? (fileTrayViewModel.items.isEmpty == false)

        guard settingsViewModel.isLiveActivityEnabled(.drop),
              settingsViewModel.mediaAndFiles.isTrayLiveActivityEnabled,
              hasTrayItems else {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.trayActive.id))
            return
        }

        notchViewModel.send(
            .showLiveActivity(
                TrayActiveNotchContent(
                    fileTrayViewModel: fileTrayViewModel,
                    mediaSettings: settingsViewModel.mediaAndFiles
                )
            )
        )
    }

    private func setupItemCallbacks() {
        self.fileTrayViewModel.onItemsChange = { [weak self] items in
            guard let self else { return }
            self.syncFileTrayLiveActivity(hasItems: !items.isEmpty)
        }

        self.airDropViewModel.$activeTransfer
            .sink { [weak self] _ in
                self?.syncAirDropTransferLiveActivity()
            }
            .store(in: &cancellables)
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

    func hideDragAndDropActivities() {
        NotchContentRegistry.DragAndDrop.liveActivityIDs.forEach { id in
            notchViewModel.send(.hideLiveActivity(id: id))
        }
    }

    func hideAllDragAndDropActivities() {
        hideDragAndDropActivities()
        notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.trayActive.id))
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
