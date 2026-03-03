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
    @ObservedObject var doNotDisturbViewModel: DoNotDisturbViewModel
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            notchBody
                .environment(\.notchScale, notchViewModel.notchModel.scale)
                .onReceive(powerViewModel.$event.compactMap { $0 }.receive(on: RunLoop.main), perform: notchEventCoordinator.handlePowerEvent)
                .onReceive(bluetoothViewModel.$event.compactMap { $0 }.receive(on: RunLoop.main), perform: notchEventCoordinator.handleBluetoothEvent)
                .onReceive(networkViewModel.$networkEvent.compactMap { $0 }.receive(on: RunLoop.main), perform: notchEventCoordinator.handleNetworkEvent)
                .onReceive(doNotDisturbViewModel.$focusEvent.compactMap{ $0 }.receive(on: RunLoop.main), perform: notchEventCoordinator.handleDoNotDisturbEvent)
                .onChange(of: notchViewModel.notchModel.content?.id) { _, newId in
                    notchViewModel.handleStrokeVisibility()
                }
                .onChange(of: airDropViewModel.isDraggingFile) { _, isTargeted in
                    if isTargeted {
                        notchEventCoordinator.handleAirDropDragStarted()
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if !airDropViewModel.isDraggingFile {
                                notchEventCoordinator.handleAirDropDragEnded()
                            }
                        }
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: $airDropViewModel.isDraggingFile) { providers in
                    let frame = notchViewModel.window?.contentView?.frame ?? .zero
                    let dropPoint = NSPoint(x: frame.midX, y: frame.midY)
                    airDropViewModel.handleDrop(providers: providers, point: dropPoint)
                    return true
                }
        }
        .windowHover(notchViewModel.window)
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
        .stroke(notchViewModel.showStroke ? notchViewModel.cachedStrokeColor : Color.clear, lineWidth: 1.5)
        .overlay { contentOverlay }
        .customNotchPressable(isPressed: $notchViewModel.isPressed, baseSize: notchViewModel.notchModel.size)
        .frame(width: notchViewModel.notchModel.size.width, height: notchViewModel.notchModel.size.height)
        .contextMenu { contextMenuItem }
        .animation(.easeInOut(duration: 0.3), value: notchViewModel.showStroke)
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
