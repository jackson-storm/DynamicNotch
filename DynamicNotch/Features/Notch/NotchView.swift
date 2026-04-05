import SwiftUI
import Combine
internal import AppKit
import UniformTypeIdentifiers

struct NotchView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    @ObservedObject var powerViewModel: PowerViewModel
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var networkViewModel: NetworkViewModel
    @ObservedObject var downloadViewModel: DownloadViewModel
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @ObservedObject var airDropController: NotchAirDropController
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    
    var body: some View {
        ZStack(alignment: .top) {
            notchBody
                .environment(\.notchScale, notchViewModel.notchModel.scale)
                .background(
                    NotchEventHandlersView(
                        notchEventCoordinator: notchEventCoordinator,
                        powerViewModel: powerViewModel,
                        bluetoothViewModel: bluetoothViewModel,
                        networkViewModel: networkViewModel,
                        downloadViewModel: downloadViewModel,
                        focusViewModel: focusViewModel,
                        airDropViewModel: airDropViewModel,
                        settingsViewModel: settingsViewModel,
                        nowPlayingViewModel: nowPlayingViewModel,
                        lockScreenManager: lockScreenManager
                    )
                )
                .onChange(of: notchViewModel.notchModel.content?.id) {
                    notchViewModel.handleStrokeVisibility()
                }
                .onChange(of: settingsViewModel.notchWidth) {
                    notchViewModel.updateDimensions()
                }
                .onChange(of: settingsViewModel.notchHeight) {
                    notchViewModel.updateDimensions()
                }
            
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(Color.black)
                .frame(
                    width: notchViewModel.notchModel.baseWidth - 10,
                    height: notchViewModel.notchModel.baseHeight - 5
                )
                .offset(y: 1)
                .customNotchPressable(
                    notchViewModel: notchViewModel,
                    isPressed: $notchViewModel.isPressed,
                    baseSize: notchViewModel.interactiveNotchSize
                )
                .contextMenu {
                    if !settingsViewModel.isMenuBarIconVisible {
                        contextMenuItem
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private extension NotchView {
    @ViewBuilder
    var notchBody: some View {
        NotchShape(
            topCornerRadius: notchViewModel.interactiveCornerRadius.top,
            bottomCornerRadius: notchViewModel.interactiveCornerRadius.bottom
        )
        .fill(.black)
        .stroke(
            settingsViewModel.isShowNotchStrokeEnabled ?
            visibleStrokeColor : Color.clear,
            lineWidth: settingsViewModel.notchStrokeWidth
        )
        .overlay {
            contentOverlay
        }
        .overlay {
            AirDropDestinationView(
                isTargeted: $airDropController.isTargeted,
                isDropZoneTargeted: Binding(
                    get: { airDropViewModel.isDropZoneTargeted },
                    set: { airDropViewModel.setDropZoneTargeted($0) }
                ),
                onDropPasteboard: { pasteboard in
                    airDropController.handlePasteboardDrop(pasteboard)
                }
            )
        }
        .frame(
            width: notchViewModel.interactiveNotchSize.width,
            height: notchViewModel.interactiveNotchSize.height
        )
        .offset(y: 1)
        .customNotchPressable(
            notchViewModel: notchViewModel,
            isPressed: $notchViewModel.isPressed,
            baseSize: notchViewModel.interactiveNotchSize
        )
        .customNotchSwipeDismissable(
            notchViewModel: notchViewModel
        )
        .contextMenu {
            if !settingsViewModel.isMenuBarIconVisible {
                contextMenuItem
            }
        }
        .animation(notchViewModel.animations.strokeVisibility, value: settingsViewModel.isShowNotchStrokeEnabled)
        .animation(notchViewModel.animations.notchVisibility, value: notchViewModel.showNotch)
    }
    
    var visibleStrokeColor: Color {
        notchViewModel.notchModel.content?.strokeColor ?? notchViewModel.cachedStrokeColor
    }
    
    @ViewBuilder
    var contentOverlay: some View {
        if let content = notchViewModel.notchModel.content {
            renderedContentView(for: content)
                .id(notchViewModel.notchModel.presentationID)
                .transition(
                    notchViewModel.contentTransition(
                        offsetX: notchViewModel.notchModel.offsetXTransition,
                        offsetY: notchViewModel.notchModel.offsetYTransition
                    )
                )
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
        Button {
            openWindow(id: SettingsScene.id)
        } label: {
            Image(systemName: "gearshape")
            Text(verbatim: "Settings")
        }
        
        Divider()
        
        Button(action: { AppRelauncher.restartApp() }) {
            Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
            Text(verbatim: "Restart")
        }
        
        Button(action: { NSApp.terminate(nil) }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
            Text(verbatim: "Quit")
        }
    }
}

private struct NotchEventHandlersView: View {
    let notchEventCoordinator: NotchEventCoordinator
    let powerViewModel: PowerViewModel
    let bluetoothViewModel: BluetoothViewModel
    let networkViewModel: NetworkViewModel
    let downloadViewModel: DownloadViewModel
    let focusViewModel: FocusViewModel
    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel
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
            .onReceive(downloadViewModel.$event.compactMap { $0 }) { event in
                notchEventCoordinator.handleDownloadEvent(event)
            }
            .onReceive(focusViewModel.$focusEvent.compactMap { $0 }) { event in
                notchEventCoordinator.handleFocusEvent(event)
            }
            .onReceive(airDropViewModel.$event.compactMap { $0 }) { event in
                notchEventCoordinator.handleAirDropEvent(event)
            }
            .onReceive(settingsViewModel.notchSizeEvent) { event in
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
