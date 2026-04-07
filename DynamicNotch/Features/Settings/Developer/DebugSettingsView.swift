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
    
    private var persistentPreviewsCard: some View {
        SettingsCard(
            title: "Persistent Events",
            subtitle: "Toggle persistent previews to inspect their live activity UI."
        ) {
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
                title: "Lock Screen",
                description: "Preview the lock live activity without actually locking macOS.",
                systemImage: "lock.fill",
                color: .black,
                isOn: $viewModel.isLockScreenPreviewEnabled,
                accessibilityIdentifier: "settings.debug.lockScreen"
            )
        }
    }
    
    private var triggerEventsCard: some View {
        SettingsCard(
            title: "Trigger Events",
            subtitle: "Trigger one-shot notifications whenever you need them."
        ) {
            DebugActionRow(
                title: "Play All Events",
                description: "Run every debug event in sequence, keep each item visible for its configured duration, wait 1 second between items, and skip onboarding, notch size, and lock screen previews.",
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
                title: "Focus Off",
                description: "Hide the Focus live activity and show the short \"Off\" notification.",
                systemImage: "moon.zzz.fill",
                color: .gray,
                action: viewModel.triggerFocusOffPreview
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
                title: "VPN Connected",
                description: "Show the VPN notification with sample tunnel data.",
                systemImage: "network.badge.shield.half.filled",
                color: .blue,
                action: viewModel.triggerVPNPreview
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
        SettingsCard(
            title: "Utilities",
            subtitle: "Clean up previews without restarting the app."
        ) {
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
struct DebugSequenceNotchContent: NotchContentProtocol {
    let id: String
    let priority: Int
    let base: any NotchContentProtocol
    
    var strokeColor: Color { base.strokeColor }
    var offsetXTransition: CGFloat { base.offsetXTransition }
    var offsetYTransition: CGFloat { base.offsetYTransition }
    var expandedOffsetXTransition: CGFloat { base.expandedOffsetXTransition }
    var expandedOffsetYTransition: CGFloat { base.expandedOffsetYTransition }
    var isExpandable: Bool { base.isExpandable }
    var expandsOnTap: Bool { base.expandsOnTap }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        base.size(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        base.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        base.cornerRadius(baseRadius: baseRadius)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        base.expandedCornerRadius(baseRadius: baseRadius)
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

struct DebugOnboardingPreviewNotchContent: NotchContentProtocol {
    let id = "onboarding"
    
    var priority: Int { 100 }
    var offsetXTransition: CGFloat { -30 }
    var offsetYTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight + 120)
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 36)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(DebugOnboardingPreviewView())
    }
}

struct DebugOnboardingPreviewView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "sparkles.tv.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
            
            Text("Onboarding Preview")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            
            Text("Debug-only safe preview of the onboarding live activity.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 34)
        .padding(.bottom, 24)
    }
}
#endif
