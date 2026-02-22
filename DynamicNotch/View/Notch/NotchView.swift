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
                .onChange(of: notchViewModel.state.content) { _, newValue in
                    notchViewModel.handleStrokeVisibility(newValue)
                }
                .onReceive(powerViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handlePowerEvent)
                .onReceive(bluetoothViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handleBluetoothEvent)
                .onReceive(vpnViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handleVpnEvent)
                .onTapGesture {
                    if case .music = notchViewModel.state.content {
                        notchViewModel.toggleMusicExpanded()
                    }
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
        .stroke(notchViewModel.showNotch ? notchViewModel.state.content.strokeColor : Color.clear, lineWidth: 2)
        .overlay { contentOverlay }
        .customNotchPressable(isPressed: $isPressed, baseSize: notchViewModel.state.size)
        .frame(width: notchViewModel.state.size.width, height: notchViewModel.state.size.height)
        .contextMenu { contextMenuItem }
        .animation(.spring(duration: 0.6), value: notchViewModel.showNotch)
    }
    
    @ViewBuilder
    var contentOverlay: some View {
        if notchViewModel.state.content != .none {
            Group {
                switch notchViewModel.state.content {
                case .none: Color.clear
                    
                case .music(.none): PlayerNotchSmall(playerViewModel: playerViewModel)
                case .music(.expanded): PlayerNotchLarge(playerViewModel: playerViewModel)
                    
                case .bluetooth: BluetoothNotchView(bluetoothViewModel: bluetoothViewModel)
                case .onboarding: OnboardingNotchView(notchEventCoordinator: notchEventCoordinator)
                    
                case .battery(.charger): ChargerNotchView(powerSourceMonitor: powerViewModel.powerMonitor)
                case .battery(.lowPower): LowPowerNotchView(powerSourceMonitor: powerViewModel.powerMonitor)
                case .battery(.fullPower): FullPowerNotchView(powerSourceMonitor: powerViewModel.powerMonitor)
                    
                case .systemHud(.display): HudDisplayView()
                case .systemHud(.keyboard): HudKeyboardView()
                case .systemHud(.volume): HudVolumeView()
                    
                case .vpn(.connected): VpnConnectView()
                case .vpn(.disconnected) : VpnDisconnectView()
                    
                }
            }
            .transition(
                .blurAndFade
                    .animation(.spring(duration: 0.5))
                    .combined(with: .scale)
                    .combined(with: .offset(y: notchViewModel.state.offsetYTransition)
                )
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
