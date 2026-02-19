import SwiftUI
import Combine
import AppKit

struct NotchView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var powerViewModel: PowerViewModel
    @ObservedObject var playerViewModel: PlayerViewModel
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @Environment(\.openWindow) private var openWindow
    
    @State private var isPressed = false
    
    let window: NSWindow?
    
    var body: some View {
        VStack {
            notchBody
                .notchPressable(isPressed: $isPressed)
                .onChange(of: notchViewModel.state.content) { _, newValue in
                    notchViewModel.handleStrokeVisibility(newValue)
                }
                .onReceive(powerViewModel.$event.compactMap { $0 }, perform: notchViewModel.handlePowerEvent)
                .onReceive(bluetoothViewModel.$event.compactMap { $0 }, perform: notchViewModel.handleBluetoothEvent)
                .onTapGesture {
                    if notchViewModel.state.content == .music {
                        notchViewModel.toggleMusicExpanded()
                    }
                }
        }
        .windowHover(window)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .offset(y: -0.3)
    }
}

private extension NotchView {
    @ViewBuilder
    var notchBody: some View {
        ZStack {
            NotchShape(
                topCornerRadius: notchViewModel.state.cornerRadius.top,
                bottomCornerRadius: notchViewModel.state.cornerRadius.bottom
            )
            .stroke(notchViewModel.showNotch ? Color.white.opacity(0.1) : Color.clear, lineWidth: 4)
            .allowsHitTesting(false)
            .animation(.spring(duration: 0.6), value: notchViewModel.showNotch)
            
            NotchShape(
                topCornerRadius: notchViewModel.state.cornerRadius.top,
                bottomCornerRadius: notchViewModel.state.cornerRadius.bottom
            )
            .fill(.black)
            .overlay { contentOverlay }
        }
        .frame(width: notchViewModel.state.size.width, height: notchViewModel.state.size.height)
        .contextMenu { contextMenuItem }
    }
    
    @ViewBuilder
    var contentOverlay: some View {
        if notchViewModel.state.content != .none {
            Group {
                switch notchViewModel.state.content {
                case .none:
                    Color.clear
                    
                case .music:
                    if notchViewModel.state.isExpanded {
                        PlayerNotchLarge(playerViewModel: playerViewModel)
                    } else {
                        PlayerNotchSmall(playerViewModel: playerViewModel)
                    }
                    
                case .charger:
                    ChargerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
                    
                case .lowPower:
                    LowPowerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
                    
                case .fullPower:
                    FullPowerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
                    
                case .bluetooth:
                    BluetoothNotch(bluetoothViewModel: bluetoothViewModel)
                    
                case .systemHud:
                    SystemHudNotch(notchViewModel: notchViewModel)
                }
            }
            .transition(
                .blurAndFade
                    .animation(.spring(duration: 0.5))
                    .combined(with: .scale)
                    .combined(with: .offset(
                        x: notchViewModel.state.offsetXTransition,
                        y: notchViewModel.state.offsetYTransition
                    )
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
