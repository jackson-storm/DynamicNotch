import SwiftUI
import Combine
import AppKit

struct NotchView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    @ObservedObject var powerViewModel: PowerViewModel
    @ObservedObject var playerViewModel: PlayerViewModel
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var vpnViewModel: VpnViewModel
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var isPressed = false
    
    let window: NSWindow?
    
    var body: some View {
        ZStack(alignment: .top) {
            notchBody
                .environment(\.notchScale, notchViewModel.state.scale)
                .onReceive(powerViewModel.$event.compactMap { $0 }.receive(on: RunLoop.main), perform: notchEventCoordinator.handlePowerEvent)
                .onReceive(bluetoothViewModel.$event.compactMap { $0 }.receive(on: RunLoop.main), perform: notchEventCoordinator.handleBluetoothEvent)
                .onReceive(vpnViewModel.$event.compactMap { $0 }.receive(on: RunLoop.main), perform: notchEventCoordinator.handleVpnEvent)
                .onTapGesture {
                    if let contentId = notchViewModel.state.content?.id, contentId.hasPrefix("player.compact") {
                        notchViewModel.toggleMusicExpanded()
                    }
                }
                .onChange(of: notchViewModel.state.content?.id) { _, newId in
                    notchViewModel.handleStrokeVisibility()
                }
        }
        .windowHover(window)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private extension NotchView {
    @ViewBuilder
    var notchBody: some View {
        NotchShape(
            topCornerRadius: notchViewModel.state.cornerRadius.top,
            bottomCornerRadius: notchViewModel.state.cornerRadius.bottom
        )
        .fill(.black)
        .stroke(notchViewModel.showNotch ? notchViewModel.state.strokeColor : Color.clear, lineWidth: 2)
        .overlay { contentOverlay }
        .customNotchPressable(isPressed: $isPressed, baseSize: notchViewModel.state.size)
        .frame(width: notchViewModel.state.size.width, height: notchViewModel.state.size.height)
        .contextMenu { contextMenuItem }
        .animation(.spring(duration: 0.6), value: notchViewModel.showNotch)
    }
    
    @ViewBuilder
    var contentOverlay: some View {
        if let content = notchViewModel.state.content {
            content.makeView()
                .id(content.id)
                .transition(
                    .blurAndFade
                        .animation(.spring(duration: 0.5))
                        .combined(with: .scale)
                        .combined(with: .offset(y: notchViewModel.state.offsetYTransition))
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
