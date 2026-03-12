import SwiftUI
import Combine
import AppKit
internal import UniformTypeIdentifiers

struct NotchView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    @ObservedObject var powerViewModel: PowerViewModel
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var networkViewModel: NetworkViewModel
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    
    var body: some View {
        ZStack {
            notchBody
                .environment(\.notchScale, notchViewModel.notchModel.scale)
                .onReceive(powerViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handlePowerEvent)
                .onReceive(bluetoothViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handleBluetoothEvent)
                .onReceive(networkViewModel.$networkEvent.compactMap { $0 }, perform: notchEventCoordinator.handleNetworkEvent)
                .onReceive(focusViewModel.$focusEvent.compactMap{ $0 }, perform: notchEventCoordinator.handleFocusEvent)
                .onReceive(airDropViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handleAirDropEvent)
                .onReceive(generalSettingsViewModel.notchSizeEvent, perform: notchEventCoordinator.handleNotchWidthEvent)
                .onChange(of: notchViewModel.notchModel.content?.id) {
                    notchViewModel.handleStrokeVisibility()
                }
                .onChange(of: generalSettingsViewModel.notchWidth) {
                    notchViewModel.updateDimensions()
                }
                .onChange(of: generalSettingsViewModel.notchHeight) {
                    notchViewModel.updateDimensions()
                }
                .onDrop(of: [.fileURL], isTargeted: $airDropViewModel.isDraggingFile) { providers in
                    let dropPoint = NSEvent.mouseLocation
                    airDropViewModel.handleDrop(providers: providers, point: dropPoint)
                    return true
                }
        }
        .offset(y: 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private extension NotchView {
    @ViewBuilder
    var notchBody: some View {
        NotchShape(
            topCornerRadius: notchViewModel.notchModel.cornerRadius.top,
            bottomCornerRadius: notchViewModel.notchModel.cornerRadius.bottom
        )
        .fill(.black)
        .stroke(
            generalSettingsViewModel.isShowNotchStrokeEnabled ?
            notchViewModel.cachedStrokeColor : Color.clear,
            lineWidth: generalSettingsViewModel.notchStrokeWidth
        )
        .overlay {
            contentOverlay
        }
        .customNotchPressable(
            isPressed: $notchViewModel.isPressed,
            baseSize: notchViewModel.notchModel.size
        )
        .frame(
            width: notchViewModel.notchModel.size.width,
            height: notchViewModel.notchModel.size.height
        )
        .contextMenu {
            if !generalSettingsViewModel.isMenuBarIconVisible {
                contextMenuItem
            }
        }
        .animation(.easeInOut(duration: 0.3), value: generalSettingsViewModel.isShowNotchStrokeEnabled)
        .animation(.spring(duration: 0.6), value: notchViewModel.showNotch)
    }
    
    @ViewBuilder
    var contentOverlay: some View {
        if let content = notchViewModel.notchModel.content {
            content.makeView()
                .id(content.id)
                .transition(
                    .blurAndFade
                        .animation(.spring(duration: 0.5))
                        .combined(with: .scale)
                        .combined(with: .offset(y: notchViewModel.notchModel.offsetYTransition))
                )
        }
    }
    
    @ViewBuilder
    var contextMenuItem: some View {
        SettingsLink {
            Image(systemName: "gearshape")
            Text("Settings")
        }
        
        Divider()
        Button(action: { NSApp.terminate(nil) }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
            Text("Quit")
        }
    }
}
