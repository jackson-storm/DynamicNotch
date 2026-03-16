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
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    
    var body: some View {
        ZStack {
            notchBody
                .environment(\.notchScale, notchViewModel.notchModel.scale)
                .background(
                    NotchEventHandlersView(
                        notchEventCoordinator: notchEventCoordinator,
                        powerViewModel: powerViewModel,
                        bluetoothViewModel: bluetoothViewModel,
                        networkViewModel: networkViewModel,
                        focusViewModel: focusViewModel,
                        airDropViewModel: airDropViewModel,
                        generalSettingsViewModel: generalSettingsViewModel,
                        nowPlayingViewModel: nowPlayingViewModel,
                        lockScreenManager: lockScreenManager
                    )
                )
                .onChange(of: notchViewModel.notchModel.content?.id) {
                    notchViewModel.handleStrokeVisibility()
                }
                .onChange(of: generalSettingsViewModel.notchWidth) {
                    notchViewModel.updateDimensions()
                }
                .onChange(of: generalSettingsViewModel.notchHeight) {
                    notchViewModel.updateDimensions()
                }
                .onDrop(of: [.fileURL], isTargeted: airDropTargetBinding) { providers in
                    guard generalSettingsViewModel.isLiveActivityEnabled(.airDrop) else {
                        return false
                    }

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
    var airDropTargetBinding: Binding<Bool> {
        Binding(
            get: {
                generalSettingsViewModel.isLiveActivityEnabled(.airDrop) &&
                airDropViewModel.isDraggingFile
            },
            set: { isTargeted in
                airDropViewModel.isDraggingFile =
                generalSettingsViewModel.isLiveActivityEnabled(.airDrop) ? isTargeted : false
            }
        )
    }

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
            notchViewModel: notchViewModel,
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
            if notchViewModel.canExpandActiveLiveActivity {
                renderedContentView(for: content)
                    .id(notchViewModel.notchModel.presentationID)
                    .transition(
                        .blurAndFade
                            .animation(.spring(duration: 0.6))
                            .combined(with: .scale)
                            .combined(with: .offset(
                                x: notchViewModel.notchModel.offsetXTransition,
                                y: notchViewModel.notchModel.offsetYTransition)
                            )
                    )
            } else {
                renderedContentView(for: content)
                    .id(notchViewModel.notchModel.presentationID)
                    .transition(
                        .blurAndFade
                            .animation(.spring(duration: 0.6))
                            .combined(with: .scale)
                            .combined(with: .offset(
                                x: notchViewModel.notchModel.offsetXTransition,
                                y: notchViewModel.notchModel.offsetYTransition)
                            )
                    )
            }
        }
    }
    
    @MainActor
    @ViewBuilder
    func renderedContentView(for content: NotchContentProtocol) -> some View {
        if notchViewModel.notchModel.isPresentingExpandedLiveActivity {
            content.makeExpandedView()
        } else {
            content.makeView()
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

private struct NotchEventHandlersView: View {
    let notchEventCoordinator: NotchEventCoordinator
    let powerViewModel: PowerViewModel
    let bluetoothViewModel: BluetoothViewModel
    let networkViewModel: NetworkViewModel
    let focusViewModel: FocusViewModel
    let airDropViewModel: AirDropNotchViewModel
    let generalSettingsViewModel: GeneralSettingsViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let lockScreenManager: LockScreenManager
    
    var body: some View {
        Color.clear
            .onReceive(powerViewModel.$event.compactMap { $0 }) { event in
                notchEventCoordinator.handlePowerEvent(event)
            }
            .onReceive(bluetoothViewModel.$event.compactMap { $0 }) { event in
                notchEventCoordinator.handleBluetoothEvent(event)
            }
            .onReceive(networkViewModel.$networkEvent.compactMap { $0 }) { event in
                notchEventCoordinator.handleNetworkEvent(event)
            }
            .onReceive(focusViewModel.$focusEvent.compactMap { $0 }) { event in
                notchEventCoordinator.handleFocusEvent(event)
            }
            .onReceive(airDropViewModel.$event.compactMap { $0 }) { event in
                notchEventCoordinator.handleAirDropEvent(event)
            }
            .onReceive(generalSettingsViewModel.notchSizeEvent) { event in
                notchEventCoordinator.handleNotchWidthEvent(event)
            }
            .onReceive(nowPlayingViewModel.$event.compactMap { $0 }) { event in
                notchEventCoordinator.handleNowPlayingEvent(event)
            }
            .onReceive(lockScreenManager.$event.compactMap { $0 }) { event in
                notchEventCoordinator.handleLockScreenEvent(event)
            }
    }
}
