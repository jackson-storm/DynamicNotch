#if DEBUG
import SwiftUI
import Combine

struct DebugSettingsView: View {
    @ObservedObject var viewModel: DebugSettingsViewModel
    
    var body: some View {
        SettingsPageScrollView {
            persistentPreviewsCard
            triggerEventsCard
            utilitiesCard
        }
        .accessibilityIdentifier("settings.debug.root")
    }

    private var debugDivider: some View {
        Divider()
            .opacity(0.6)
            .padding(.leading, 43)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
    
    private var persistentPreviewsCard: some View {
        SettingsCard(title: "Persistent Events") {
            SettingsToggleRow(
                title: "Onboarding",
                description: "Show a safe debug preview of the onboarding live activity.",
                systemImage: "sparkles.rectangle.stack",
                color: .pink,
                isOn: $viewModel.isOnboardingPreviewEnabled,
                accessibilityIdentifier: "settings.debug.onboarding"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Focus On",
                description: "Preview the persistent Focus live activity.",
                systemImage: "moon.fill",
                color: .indigo,
                isOn: $viewModel.isFocusLivePreviewEnabled,
                accessibilityIdentifier: "settings.debug.focusOn"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "Screen Recording",
                description: "Preview the persistent screen recording indicator.",
                systemImage: "record.circle.fill",
                color: .red,
                isOn: $viewModel.isScreenRecordingPreviewEnabled,
                accessibilityIdentifier: "settings.debug.screenRecording"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Hotspot Active",
                description: "Keep the hotspot live activity visible until you turn it off.",
                systemImage: "personalhotspot",
                color: .green,
                isOn: $viewModel.isHotspotPreviewEnabled,
                accessibilityIdentifier: "settings.debug.hotspot"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Now Playing",
                description: "Show the music live activity with sample track data.",
                systemImage: "music.note",
                color: .orange,
                isOn: $viewModel.isNowPlayingPreviewEnabled,
                accessibilityIdentifier: "settings.debug.nowPlaying"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Downloads",
                description: "Show the download live activity with sample transfer data.",
                systemImage: "arrow.down.doc.fill",
                color: .blue,
                isOn: $viewModel.isDownloadPreviewEnabled,
                accessibilityIdentifier: "settings.debug.downloads"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Timer",
                description: "Show the timer live activity with sample transfer data.",
                systemImage: "gauge.with.needle",
                color: .orange,
                isOn: $viewModel.isTimerPreviewEnabled,
                accessibilityIdentifier: "settings.debug.timer"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "File Tray Active",
                description: "Show the active tray live activity with sample files.",
                systemImage: "tray.full.fill",
                color: .white,
                isOn: $viewModel.isFileTrayPreviewEnabled,
                accessibilityIdentifier: "settings.debug.fileTrayActive"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "File Converter Active",
                description: "Show the converter live activity with a sample image.",
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill",
                color: .green,
                isOn: $viewModel.isFileConverterPreviewEnabled,
                accessibilityIdentifier: "settings.debug.fileConverterActive"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Lock Screen",
                description: "Preview the lock live activity without actually locking macOS.",
                systemImage: "lock.fill",
                color: .black,
                isOn: $viewModel.isLockScreenPreviewEnabled,
                accessibilityIdentifier: "settings.debug.lockScreen"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Software Update",
                description: "Preview the software update available live activity.",
                systemImage: "arrow.clockwise.circle.fill",
                color: .blue,
                isOn: $viewModel.isSoftwareUpdatePreviewEnabled,
                accessibilityIdentifier: "settings.debug.softwareUpdate"
            )
        }
    }
    
    private var triggerEventsCard: some View {
        SettingsCard(title: "Trigger Events") {
            DebugActionRow(
                title: "Play All Events",
                description: "Run every debug event in sequence, keep each item visible for its configured duration, and wait 1 second between items.",
                systemImage: viewModel.isPreviewSequenceRunning ? "stop.circle.fill" : "play.circle.fill",
                color: .accentColor,
                buttonTitle: viewModel.isPreviewSequenceRunning ? LocalizedStringKey("Stop") : LocalizedStringKey("Start"),
                action: viewModel.togglePreviewSequence
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            DebugActionRow(
                title: "AirDrop Target",
                description: "Show the AirDrop drag target as an active drag event.",
                systemImage: "airplayaudio",
                color: .blue,
                action: viewModel.triggerAirDropTargetPreview
            )

            debugDivider

            DebugActionRow(
                title: "Tray Target",
                description: "Show the Tray drag target as an active drag event.",
                systemImage: "tray.full.fill",
                color: .white,
                action: viewModel.triggerTrayTargetPreview
            )

            debugDivider

            DebugActionRow(
                title: "Converter Target",
                description: "Show the File Converter drag target as an active drag event.",
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill",
                color: .green,
                action: viewModel.triggerFileConverterTargetPreview
            )

            debugDivider

            DebugActionRow(
                title: "Combined Targets",
                description: "Show all drag targets with the converter target highlighted.",
                systemImage: "square.grid.3x3.fill",
                color: .accentColor,
                action: viewModel.triggerCombinedDragAndDropPreview
            )

            debugDivider

            DebugActionRow(
                title: "Drag Ended",
                description: "Hide active drag targets with the drag-ended event.",
                systemImage: "xmark.circle.fill",
                color: .gray,
                action: viewModel.triggerDragAndDropEndedPreview
            )

            debugDivider

            DebugActionRow(
                title: "Drop Completed",
                description: "Finish an active drag with the dropped event.",
                systemImage: "checkmark.circle.fill",
                color: .green,
                action: viewModel.triggerDragAndDropDroppedPreview
            )

            debugDivider

            DebugActionRow(
                title: "Converter Converting",
                description: "Show the converter collapsed converting state.",
                systemImage: "arrow.triangle.2.circlepath",
                color: .accentColor,
                action: viewModel.triggerFileConverterConvertingPreview
            )

            debugDivider

            DebugActionRow(
                title: "Converter Failed",
                description: "Show the converter collapsed failed state.",
                systemImage: "exclamationmark.triangle.fill",
                color: .yellow,
                action: viewModel.triggerFileConverterFailedPreview
            )

            debugDivider

            DebugActionRow(
                title: "Converter Success",
                description: "Show the converter collapsed success state.",
                systemImage: "checkmark.seal.fill",
                color: .green,
                action: viewModel.triggerFileConverterConvertedPreview
            )

            debugDivider
            
            DebugActionRow(
                title: "Focus Off",
                description: "Hide the Focus live activity and show the short \"Off\" notification.",
                systemImage: "moon.zzz.fill",
                color: .gray,
                action: viewModel.triggerFocusOffPreview
            )

            debugDivider

            DebugActionRow(
                title: "Screen Recording Stopped",
                description: "Hide the screen recording live activity.",
                systemImage: "stop.circle.fill",
                color: .red,
                action: viewModel.triggerScreenRecordingStoppedPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Bluetooth Connected",
                description: "Show the Bluetooth notification with sample AirPods data.",
                systemImage: "bolt.horizontal.circle.fill",
                color: .blue,
                action: viewModel.triggerBluetoothPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Wi-Fi Connected",
                description: "Shows the Wi-Fi temporary notification.",
                systemImage: "wifi",
                color: .blue,
                action: viewModel.triggerWifiPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            DebugActionRow(
                title: "No Internet Connection",
                description: "Show the offline temporary notification with its actions.",
                systemImage: "wifi.slash",
                color: .red,
                action: viewModel.triggerNoInternetConnectionPreview
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "VPN Connected",
                description: "Show the VPN notification with sample tunnel data.",
                systemImage: "network.badge.shield.half.filled",
                color: .blue,
                action: viewModel.triggerVPNPreview
            )

            debugDivider

            DebugActionRow(
                title: "VPN Disconnected",
                description: "Show the VPN disconnected notification with sample tunnel data.",
                systemImage: "network.badge.shield.half.filled",
                color: .gray,
                action: viewModel.triggerVPNDisconnectedPreview
            )

            debugDivider

            DebugActionRow(
                title: "Hotspot Hidden",
                description: "Hide the hotspot live activity with the hotspot-hide event.",
                systemImage: "personalhotspot",
                color: .gray,
                action: viewModel.triggerHotspotHidePreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Charging",
                description: "Apply a sample charging state and show the charger notification.",
                systemImage: "battery.75",
                color: .green,
                action: viewModel.triggerChargingPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Battery Low",
                description: "Apply a low battery sample and show the low-power alert.",
                systemImage: "battery.25",
                color: .red,
                action: viewModel.triggerLowPowerPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Full Battery",
                description: "Apply a full battery sample and show the completion notification.",
                systemImage: "battery.100percent",
                color: .green,
                action: viewModel.triggerFullBatteryPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Brightness HUD",
                description: "Show the brightness HUD preview at 72%.",
                systemImage: "sun.max.fill",
                color: .yellow,
                action: viewModel.triggerBrightnessHUDPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Keyboard HUD",
                description: "Show the keyboard backlight HUD preview at 64%.",
                systemImage: "light.max",
                color: .mint,
                action: viewModel.triggerKeyboardHUDPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Volume HUD",
                description: "Show the volume HUD preview at 42%.",
                systemImage: "speaker.wave.2.fill",
                color: .purple,
                action: viewModel.triggerVolumeHUDPreview
            )

            debugDivider

            DebugActionRow(
                title: "Now Playing Paused",
                description: "Send the Now Playing playback-state changed event for pause.",
                systemImage: "pause.circle.fill",
                color: .orange,
                action: viewModel.triggerNowPlayingPausePreview
            )

            debugDivider

            DebugActionRow(
                title: "Now Playing Playing",
                description: "Send the Now Playing playback-state changed event for play.",
                systemImage: "play.circle.fill",
                color: .orange,
                action: viewModel.triggerNowPlayingPlayPreview
            )

            debugDivider

            DebugActionRow(
                title: "Now Playing Stopped",
                description: "Hide the Now Playing live activity with the stopped event.",
                systemImage: "stop.circle.fill",
                color: .orange,
                action: viewModel.triggerNowPlayingStoppedPreview
            )

            debugDivider

            DebugActionRow(
                title: "Download Stopped",
                description: "Hide the downloads live activity with the stopped event.",
                systemImage: "arrow.down.circle.fill",
                color: .blue,
                action: viewModel.triggerDownloadStoppedPreview
            )

            debugDivider

            DebugActionRow(
                title: "Timer Updated",
                description: "Refresh the timer live activity with the updated event.",
                systemImage: "timer",
                color: .orange,
                action: viewModel.triggerTimerUpdatedPreview
            )

            debugDivider

            DebugActionRow(
                title: "Timer Stopped",
                description: "Hide the timer live activity with the stopped event.",
                systemImage: "timer",
                color: .gray,
                action: viewModel.triggerTimerStoppedPreview
            )

            debugDivider

            DebugActionRow(
                title: "Lock Screen Stopped",
                description: "Hide the lock screen live activity with the stopped event.",
                systemImage: "lock.open.fill",
                color: .gray,
                action: viewModel.triggerLockScreenStoppedPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Notch Width Changed",
                description: "Show the width resize helper using the current settings.",
                systemImage: "arrow.left.and.right",
                color: .red,
                action: viewModel.triggerNotchWidthPreview
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            DebugActionRow(
                title: "Notch Height Changed",
                description: "Show the height resize helper using the current settings.",
                systemImage: "arrow.up.and.down",
                color: .red,
                action: viewModel.triggerNotchHeightPreview
            )
        }
    }
    
    private var utilitiesCard: some View {
        SettingsCard(title: "Utilities") {
            DebugActionRow(
                title: "Hide Current Temporary",
                description: "Dismiss the currently visible temporary notification.",
                systemImage: "eye.slash.fill",
                color: .gray,
                action: viewModel.hideCurrentTemporaryPreview
            )
            
            Divider().opacity(0.6)
            
            DebugActionRow(
                title: "Reset All Previews",
                description: "Turn off every persistent preview and close any temporary content.",
                systemImage: "arrow.counterclockwise.circle.fill",
                color: .red,
                action: viewModel.resetAllPreviews
            )
        }
    }
}

struct DebugActionRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let systemImage: String
    let color: Color
    let buttonTitle: LocalizedStringKey
    let action: () -> Void
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        systemImage: String,
        color: Color,
        buttonTitle: LocalizedStringKey = "Start",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.color = color
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.gradient)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 16)
            
            Button(buttonTitle, action: action)
                .controlSize(.small)
        }
    }
}

// Wraps preview content in a debug-only identity so the sequence does not evict
// the app's real live activities that reuse the same content types.
struct DebugSequenceNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id: String
    let priority: Int
    let base: any NotchContentProtocol
    
    var strokeColor: Color { base.strokeColor }
    var isExpandable: Bool { base.isExpandable }
    var expandsOnTap: Bool { base.expandsOnTap }
    var windowLink: (@MainActor () -> Void)? { base.windowLink }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        base.size(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        base.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if let customizable = base as? DynamicIslandCustomizable {
            return customizable.dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
        }
        return base.size(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if let customizable = base as? DynamicIslandCustomizable {
            return customizable.expandedDynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
        }
        return base.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        base.cornerRadius(baseRadius: baseRadius)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        base.expandedCornerRadius(baseRadius: baseRadius)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        if let customizable = base as? DynamicIslandCustomizable {
            return customizable.dynamicIslandCornerRadius(baseHeight: baseHeight)
        }
        return baseHeight * 0.5
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        if let customizable = base as? DynamicIslandCustomizable {
            return customizable.expandedDynamicIslandCornerRadius(baseHeight: baseHeight)
        }
        return baseHeight * 0.2
    }
    
    @MainActor
    func makeView() -> AnyView {
        base.makeView()
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        base.makeExpandedView()
    }
}
#endif
