import SwiftUI

struct NotchDragAndDropDestinationOverlay: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @ObservedObject var airDropController: NotchAirDropController
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        DragAndDropDestinationView(
            isTargeted: $airDropController.isTargeted,
            targetedDropTarget: Binding(
                get: { airDropViewModel.targetedDropTarget },
                set: { airDropViewModel.setTargetedDropTarget($0) }
            ),
            mode: settingsViewModel.mediaAndFiles.dragAndDropActivityMode,
            onDropPasteboard: { target, pasteboard in
                switch target {
                case .airDrop:
                    guard settingsViewModel.mediaAndFiles.dragAndDropActivityMode.showsAirDrop,
                          settingsViewModel.mediaAndFiles.isAirDropLiveActivityEnabled else {
                        return false
                    }
                    
                    return airDropController.handlePasteboardDrop(pasteboard)
                case .tray:
                    guard settingsViewModel.mediaAndFiles.dragAndDropActivityMode.showsTray,
                          settingsViewModel.mediaAndFiles.isTrayLiveActivityEnabled else {
                        return false
                    }
                    
                    return airDropController.handleTrayDrop(
                        pasteboard,
                        mode: settingsViewModel.mediaAndFiles.fileTrayUsageMode
                    )
                }
            }
        )
    }
}
