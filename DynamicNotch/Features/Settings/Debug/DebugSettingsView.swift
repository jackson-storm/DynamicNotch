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
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("settings.debug.root")
    }

    private var persistentPreviewsCard: some View {
        SettingsCard(
            title: "Persistent Events",
            subtitle: "Toggle long-lived states on and off to inspect their live activity UI."
        ) {
            VStack(spacing: 16) {
                SettingsToggleRow(
                    title: "Onboarding",
                    description: "Show a safe debug preview of the onboarding live activity.",
                    systemImage: "sparkles.rectangle.stack",
                    color: .pink,
                    isOn: $viewModel.isOnboardingPreviewEnabled,
                    accessibilityIdentifier: "settings.debug.onboarding"
                )

                Divider()

                SettingsToggleRow(
                    title: "Focus On",
                    description: "Preview the persistent Focus live activity.",
                    systemImage: "moon.fill",
                    color: .indigo,
                    isOn: $viewModel.isFocusLivePreviewEnabled,
                    accessibilityIdentifier: "settings.debug.focusOn"
                )

                Divider()

                SettingsToggleRow(
                    title: "Hotspot Active",
                    description: "Keep the hotspot live activity visible until you turn it off.",
                    systemImage: "personalhotspot",
                    color: .green,
                    isOn: $viewModel.isHotspotPreviewEnabled,
                    accessibilityIdentifier: "settings.debug.hotspot"
                )

                Divider()

                SettingsToggleRow(
                    title: "Now Playing",
                    description: "Inject a sample track and show the music live activity.",
                    systemImage: "music.note",
                    color: .orange,
                    isOn: $viewModel.isNowPlayingPreviewEnabled,
                    accessibilityIdentifier: "settings.debug.nowPlaying"
                )

                Divider()

                SettingsToggleRow(
                    title: "Downloads",
                    description: "Inject sample download activity and preview the live download state.",
                    systemImage: "arrow.down.doc.fill",
                    color: .blue,
                    isOn: $viewModel.isDownloadPreviewEnabled,
                    accessibilityIdentifier: "settings.debug.downloads"
                )

                Divider()

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
    }

    private var triggerEventsCard: some View {
        SettingsCard(
            title: "Trigger Events",
            subtitle: "Fire one-shot notifications exactly when you need them."
        ) {
            VStack(spacing: 14) {
                DebugActionRow(
                    title: "Play All Events",
                    description: "Runs every debug event in sequence, keeps each item on screen for its configured time, waits 1 second, and skips onboarding, notch size, plus lock screen previews.",
                    systemImage: viewModel.isPreviewSequenceRunning ? "stop.circle.fill" : "play.circle.fill",
                    color: .accentColor,
                    buttonTitle: viewModel.isPreviewSequenceRunning ? "Stop" : "Start",
                    action: viewModel.togglePreviewSequence
                )

                Divider()

                DebugActionRow(
                    title: "Focus Off",
                    description: "Hides Focus live state and shows the short \"Off\" notification.",
                    systemImage: "moon.zzz.fill",
                    color: .gray,
                    action: viewModel.triggerFocusOffPreview
                )

                Divider()

                DebugActionRow(
                    title: "Bluetooth Connected",
                    description: "Uses sample AirPods metadata and shows the Bluetooth notification.",
                    systemImage: "bolt.horizontal.circle.fill",
                    color: .blue,
                    action: viewModel.triggerBluetoothPreview
                )

                Divider()

                DebugActionRow(
                    title: "Wi-Fi Connected",
                    description: "Shows the Wi-Fi temporary notification.",
                    systemImage: "wifi",
                    color: .blue,
                    action: viewModel.triggerWifiPreview
                )

                Divider()

                DebugActionRow(
                    title: "VPN Connected",
                    description: "Uses sample VPN metadata and shows the secure tunnel notification.",
                    systemImage: "network.badge.shield.half.filled",
                    color: .blue,
                    action: viewModel.triggerVPNPreview
                )

                Divider()

                DebugActionRow(
                    title: "Charging",
                    description: "Applies a sample charging battery state and shows the charger banner.",
                    systemImage: "battery.75",
                    color: .green,
                    action: viewModel.triggerChargingPreview
                )

                Divider()

                DebugActionRow(
                    title: "Battery Low",
                    description: "Applies a low battery sample and shows the low power alert.",
                    systemImage: "battery.25",
                    color: .red,
                    action: viewModel.triggerLowPowerPreview
                )

                Divider()

                DebugActionRow(
                    title: "Full Battery",
                    description: "Applies a fully charged sample and shows the completion state.",
                    systemImage: "battery.100percent",
                    color: .green,
                    action: viewModel.triggerFullBatteryPreview
                )

                Divider()

                DebugActionRow(
                    title: "Brightness HUD",
                    description: "Triggers the brightness HUD preview at 72%.",
                    systemImage: "sun.max.fill",
                    color: .yellow,
                    action: viewModel.triggerBrightnessHUDPreview
                )

                Divider()

                DebugActionRow(
                    title: "Keyboard HUD",
                    description: "Triggers the keyboard backlight HUD preview at 64%.",
                    systemImage: "light.max",
                    color: .mint,
                    action: viewModel.triggerKeyboardHUDPreview
                )

                Divider()

                DebugActionRow(
                    title: "Volume HUD",
                    description: "Triggers the volume HUD preview at 42%.",
                    systemImage: "speaker.wave.2.fill",
                    color: .purple,
                    action: viewModel.triggerVolumeHUDPreview
                )

                Divider()

                DebugActionRow(
                    title: "Notch Width Changed",
                    description: "Shows the width sizing helper using the current settings values.",
                    systemImage: "arrow.left.and.right",
                    color: .red,
                    action: viewModel.triggerNotchWidthPreview
                )

                Divider()

                DebugActionRow(
                    title: "Notch Height Changed",
                    description: "Shows the height sizing helper using the current settings values.",
                    systemImage: "arrow.up.and.down",
                    color: .red,
                    action: viewModel.triggerNotchHeightPreview
                )
            }
        }
    }

    private var utilitiesCard: some View {
        SettingsCard(
            title: "Utilities",
            subtitle: "Clean up previews without restarting the app."
        ) {
            VStack(spacing: 14) {
                DebugActionRow(
                    title: "Hide Current Temporary",
                    description: "Dismiss the currently visible temporary notification immediately.",
                    systemImage: "eye.slash.fill",
                    color: .gray,
                    action: viewModel.hideCurrentTemporaryPreview
                )

                Divider()

                DebugActionRow(
                    title: "Reset All Previews",
                    description: "Turns off every persistent preview and closes temporary content.",
                    systemImage: "arrow.counterclockwise.circle.fill",
                    color: .red,
                    action: viewModel.resetAllPreviews
                )
            }
        }
    }
}

struct DebugActionRow: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let buttonTitle: String
    let action: () -> Void

    init(
        title: String,
        description: String,
        systemImage: String,
        color: Color,
        buttonTitle: String = "Start",
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
