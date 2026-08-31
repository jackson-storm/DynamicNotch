#if DEBUG
import SwiftUI
import Combine

struct DebugSettingsView: View {
    @ObservedObject var viewModel: DebugSettingsViewModel
    @State private var selectedPersistentCategory: PersistentDebugCategory = .system
    @State private var selectedTriggerCategory: TriggerDebugCategory = .dragAndDrop
    @State private var selectedNotificationCategory: NotificationDebugCategory = .messages
    
    var body: some View {
        SettingsPageScrollView {
            persistentPreviewsCard
            triggerEventsCard
            notificationsPreviewsCard
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

    private enum PersistentDebugCategory: String, CaseIterable, Identifiable {
        case system
        case media
        case files

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return "System"
            case .media: return "Media"
            case .files: return "Files"
            }
        }

        var icon: String {
            switch self {
            case .system: return "gearshape.fill"
            case .media: return "music.note"
            case .files: return "folder.fill"
            }
        }
    }

    private enum TriggerDebugCategory: String, CaseIterable, Identifiable {
        case dragAndDrop
        case connectivity
        case system
        case media

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dragAndDrop: return "Drag & Drop"
            case .connectivity: return "Connectivity"
            case .system: return "System & HUD"
            case .media: return "Media & State"
            }
        }

        var icon: String {
            switch self {
            case .dragAndDrop: return "arrow.down.doc.fill"
            case .connectivity: return "antenna.radiowaves.left.and.right"
            case .system: return "slider.horizontal.3"
            case .media: return "play.circle.fill"
            }
        }
    }
    
    private var persistentPreviewsCard: some View {
        SettingsCard(title: "settings.debug.card.persistentEvents") {
            Picker("", selection: $selectedPersistentCategory) {
                ForEach(PersistentDebugCategory.allCases) { category in
                    Label {
                        Text(verbatim: category.title)
                    } icon: {
                        Image(systemName: category.icon)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 4)
            .padding(.bottom, 6)

            switch selectedPersistentCategory {
            case .system:
                persistentSystemContent
            case .media:
                persistentMediaContent
            case .files:
                persistentFilesContent
            }
        }
    }

    @ViewBuilder
    private var persistentSystemContent: some View {
        SettingsToggleRow(
            title: "Focus On",
            description: "Preview the persistent Focus live activity.",
            systemImage: "moon.fill",
            color: .indigo,
            isOn: $viewModel.isFocusLivePreviewEnabled,
            accessibilityIdentifier: "settings.debug.focusOn"
        )

        debugDivider

        SettingsToggleRow(
            title: "Screen Recording",
            description: "Preview the persistent screen recording indicator.",
            systemImage: "record.circle.fill",
            color: .red,
            isOn: $viewModel.isScreenRecordingPreviewEnabled,
            accessibilityIdentifier: "settings.debug.screenRecording"
        )

        debugDivider

        SettingsToggleRow(
            title: "Hotspot Active",
            description: "Keep the hotspot live activity visible until you turn it off.",
            systemImage: "personalhotspot",
            color: .green,
            isOn: $viewModel.isHotspotPreviewEnabled,
            accessibilityIdentifier: "settings.debug.hotspot"
        )

        debugDivider

        SettingsToggleRow(
            title: "Lock Screen",
            description: "Preview the lock live activity without actually locking macOS.",
            systemImage: "lock.fill",
            color: .black,
            isOn: $viewModel.isLockScreenPreviewEnabled,
            accessibilityIdentifier: "settings.debug.lockScreen"
        )

        debugDivider

        SettingsToggleRow(
            title: "Onboarding",
            description: "Show a safe debug preview of the onboarding live activity.",
            systemImage: "sparkles.rectangle.stack",
            color: .pink,
            isOn: $viewModel.isOnboardingPreviewEnabled,
            accessibilityIdentifier: "settings.debug.onboarding"
        )

        debugDivider

        SettingsToggleRow(
            title: "Software Update",
            description: "Preview the software update available live activity.",
            systemImage: "arrow.clockwise.circle.fill",
            color: .blue,
            isOn: $viewModel.isSoftwareUpdatePreviewEnabled,
            accessibilityIdentifier: "settings.debug.softwareUpdate"
        )
    }

    @ViewBuilder
    private var persistentMediaContent: some View {
        SettingsToggleRow(
            title: "Now Playing",
            description: "Show the music live activity with sample track data.",
            systemImage: "music.note",
            color: .orange,
            isOn: $viewModel.isNowPlayingPreviewEnabled,
            accessibilityIdentifier: "settings.debug.nowPlaying"
        )

        debugDivider

        SettingsToggleRow(
            title: "Timer",
            description: "Show the timer live activity with sample transfer data.",
            systemImage: "gauge.with.needle",
            color: .orange,
            isOn: $viewModel.isTimerPreviewEnabled,
            accessibilityIdentifier: "settings.debug.timer"
        )

        debugDivider

        SettingsToggleRow(
            title: "Downloads",
            description: "Show the download live activity with sample transfer data.",
            systemImage: "arrow.down.doc.fill",
            color: .blue,
            isOn: $viewModel.isDownloadPreviewEnabled,
            accessibilityIdentifier: "settings.debug.downloads"
        )
    }

    @ViewBuilder
    private var persistentFilesContent: some View {
        SettingsToggleRow(
            title: "File Tray Active",
            description: "Show the active tray live activity with sample files.",
            systemImage: "tray.full.fill",
            color: .white,
            isOn: $viewModel.isFileTrayPreviewEnabled,
            accessibilityIdentifier: "settings.debug.fileTrayActive"
        )

        debugDivider

        SettingsToggleRow(
            title: "File Converter Active",
            description: "Show the converter live activity with a sample image.",
            systemImage: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill",
            color: .green,
            isOn: $viewModel.isFileConverterPreviewEnabled,
            accessibilityIdentifier: "settings.debug.fileConverterActive"
        )
    }
    
    private var triggerEventsCard: some View {
        SettingsCard(title: "settings.debug.card.triggerEvents") {
            DebugActionRow(
                title: "Play All Events",
                description: "Run every debug event in sequence, keep each item visible for its configured duration, and wait 1 second between items.",
                systemImage: viewModel.isPreviewSequenceRunning ? "stop.circle.fill" : "play.circle.fill",
                color: .accentColor,
                buttonTitle: viewModel.isPreviewSequenceRunning ? "Stop" : "Start",
                action: viewModel.togglePreviewSequence
            )
            
            debugDivider

            Picker("", selection: $selectedTriggerCategory) {
                ForEach(TriggerDebugCategory.allCases) { category in
                    Label {
                        Text(verbatim: category.title)
                    } icon: {
                        Image(systemName: category.icon)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 4)
            .padding(.vertical, 4)

            switch selectedTriggerCategory {
            case .dragAndDrop:
                triggerDragAndDropContent
            case .connectivity:
                triggerConnectivityContent
            case .system:
                triggerSystemContent
            case .media:
                triggerMediaContent
            }
        }
    }

    @ViewBuilder
    private var triggerDragAndDropContent: some View {
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
            title: "AirDrop Transfer",
            description: "Show active AirDrop file transfer progress and completion.",
            imageName: "airdrop.white",
            color: .blue,
            action: viewModel.triggerAirDropTransferPreview
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
    }

    @ViewBuilder
    private var triggerConnectivityContent: some View {
        DebugActionRow(
            title: "Bluetooth Connected",
            description: "Show the Bluetooth notification with sample AirPods data.",
            systemImage: "bolt.horizontal.circle.fill",
            color: .blue,
            action: viewModel.triggerBluetoothPreview
        )

        debugDivider

        DebugActionRow(
            title: "Wi-Fi Connected",
            description: "Shows the Wi-Fi temporary notification.",
            systemImage: "wifi",
            color: .blue,
            action: viewModel.triggerWifiPreview
        )

        debugDivider

        DebugActionRow(
            title: "No Internet Connection",
            description: "Show the offline temporary notification with its actions.",
            systemImage: "wifi.slash",
            color: .red,
            action: viewModel.triggerNoInternetConnectionPreview
        )

        debugDivider

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
    }

    @ViewBuilder
    private var triggerSystemContent: some View {
        DebugActionRow(
            title: "Brightness HUD",
            description: "Show the brightness HUD preview at 72%.",
            systemImage: "sun.max.fill",
            color: .yellow,
            action: viewModel.triggerBrightnessHUDPreview
        )

        debugDivider

        DebugActionRow(
            title: "Keyboard HUD",
            description: "Show the keyboard backlight HUD preview at 64%.",
            systemImage: "light.max",
            color: .mint,
            action: viewModel.triggerKeyboardHUDPreview
        )

        debugDivider

        DebugActionRow(
            title: "Volume HUD",
            description: "Show the volume HUD preview at 42%.",
            systemImage: "speaker.wave.2.fill",
            color: .purple,
            action: viewModel.triggerVolumeHUDPreview
        )

        debugDivider

        DebugActionRow(
            title: "Charging",
            description: "Apply a sample charging state and show the charger notification.",
            systemImage: "battery.75",
            color: .green,
            action: viewModel.triggerChargingPreview
        )

        debugDivider

        DebugActionRow(
            title: "Battery Low",
            description: "Apply a low battery sample and show the low-power alert.",
            systemImage: "battery.25",
            color: .red,
            action: viewModel.triggerLowPowerPreview
        )

        debugDivider

        DebugActionRow(
            title: "Full Battery",
            description: "Apply a full battery sample and show the completion notification.",
            systemImage: "battery.100percent",
            color: .green,
            action: viewModel.triggerFullBatteryPreview
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

        debugDivider

        DebugActionRow(
            title: "Notch Width Changed",
            description: "Show the width resize helper using the current settings.",
            systemImage: "arrow.left.and.right",
            color: .red,
            action: viewModel.triggerNotchWidthPreview
        )

        debugDivider

        DebugActionRow(
            title: "Notch Height Changed",
            description: "Show the height resize helper using the current settings.",
            systemImage: "arrow.up.and.down",
            color: .red,
            action: viewModel.triggerNotchHeightPreview
        )
    }

    @ViewBuilder
    private var triggerMediaContent: some View {
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
    }
    
    private enum NotificationDebugCategory: String, CaseIterable, Identifiable {
        case messages
        case mail
        case queues
        case drives

        var id: String { rawValue }

        var title: String {
            switch self {
            case .messages: return "Messages"
            case .mail: return "Mail"
            case .queues: return "Queues"
            case .drives: return "Drives"
            }
        }

        var icon: String {
            switch self {
            case .messages: return "message.fill"
            case .mail: return "envelope.fill"
            case .queues: return "rectangle.stack.fill"
            case .drives: return "externaldrive.fill"
            }
        }
    }

    private var notificationsPreviewsCard: some View {
        SettingsCard(verbatimTitle: "Notifications Previews") {
            Picker("", selection: $selectedNotificationCategory) {
                ForEach(NotificationDebugCategory.allCases) { category in
                    Label {
                        Text(verbatim: category.title)
                    } icon: {
                        Image(systemName: category.icon)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 4)
            .padding(.bottom, 6)

            switch selectedNotificationCategory {
            case .messages:
                messagesPreviewContent
            case .mail:
                mailPreviewContent
            case .queues:
                queuesPreviewContent
            case .drives:
                drivesPreviewContent
            }
        }
    }

    @ViewBuilder
    private var messagesPreviewContent: some View {
        DebugActionRow(
            title: "Messages (Text)",
            description: "Show a standard incoming text message.",
            systemImage: "message.fill",
            color: .green,
            action: viewModel.triggerMessagesTextPreview
        )

        debugDivider

        DebugActionRow(
            title: "Messages (Text & Photo)",
            description: "Show an incoming message containing text and a photo.",
            systemImage: "photo.fill",
            color: .mint,
            action: viewModel.triggerMessagesTextAndImagePreview
        )

        debugDivider

        DebugActionRow(
            title: "Messages (Audio)",
            description: "Show an incoming playable audio message.",
            systemImage: "waveform",
            color: .orange,
            action: viewModel.triggerMessagesAudioPreview
        )

        debugDivider

        DebugActionRow(
            title: "Messages (Video)",
            description: "Show an incoming video attachment without text.",
            systemImage: "film.fill",
            color: .blue,
            action: viewModel.triggerMessagesVideoPreview
        )

        debugDivider

        DebugActionRow(
            title: "Messages (File)",
            description: "Show an incoming file attachment with its filename.",
            systemImage: "doc.fill",
            color: .indigo,
            action: viewModel.triggerMessagesFilePreview
        )

        debugDivider

        DebugActionRow(
            title: "Messages (Multiple Attachments)",
            description: "Show a message containing several image attachments.",
            systemImage: "square.grid.2x2.fill",
            color: .mint,
            action: viewModel.triggerMessagesMultipleAttachmentsPreview
        )

        debugDivider

        DebugActionRow(
            title: "Messages (Unknown Sender)",
            description: "Show an SMS from a sender without a resolved contact.",
            systemImage: "person.crop.circle.badge.questionmark.fill",
            color: .gray,
            action: viewModel.triggerMessagesUnknownSenderPreview
        )

        debugDivider

        DebugActionRow(
            title: "Messages (Long Text)",
            description: "Show a long message to verify wrapping and truncation.",
            systemImage: "text.alignleft",
            color: .green,
            action: viewModel.triggerMessagesLongContentPreview
        )
    }

    @ViewBuilder
    private var mailPreviewContent: some View {
        DebugActionRow(
            title: "Mail (Standard)",
            description: "Show standard Mail notification with sender, subject, and summary.",
            systemImage: "envelope.fill",
            color: .yellow,
            action: viewModel.triggerMailPreview
        )

        debugDivider

        DebugActionRow(
            title: "Mail (No Summary)",
            description: "Show compact Mail notification without body summary preview.",
            systemImage: "envelope.badge",
            color: .yellow,
            action: viewModel.triggerMailNoSummaryPreview
        )

        debugDivider

        DebugActionRow(
            title: "Mail (No Subject)",
            description: "Show Mail notification with empty subject line.",
            systemImage: "envelope",
            color: .yellow,
            action: viewModel.triggerMailNoSubjectPreview
        )

        debugDivider

        DebugActionRow(
            title: "Mail (No Subject & Summary)",
            description: "Show minimal Mail notification with sender only.",
            systemImage: "envelope.open",
            color: .yellow,
            action: viewModel.triggerMailNoSubjectNoSummaryPreview
        )

        debugDivider

        DebugActionRow(
            title: "Mail (Long Text)",
            description: "Show Mail notification with long sender, subject, and summary.",
            systemImage: "text.alignleft",
            color: .yellow,
            action: viewModel.triggerMailLongContentPreview
        )

        debugDivider

        DebugActionRow(
            title: "Mail (Multiple - Sequence)",
            description: "Simulate 3 consecutive emails arriving with 1.5s delay to test in-place view update.",
            systemImage: "envelope.badge.fill",
            color: .orange,
            action: viewModel.triggerMailSequencePreview
        )

        debugDivider

        DebugActionRow(
            title: "Mail (Multiple - Immediate)",
            description: "Simulate rapid incoming emails arriving in quick succession (0.4s delay).",
            systemImage: "bolt.badge.clock.fill",
            color: .orange,
            action: viewModel.triggerMailRapidPreview
        )
    }

    @ViewBuilder
    private var queuesPreviewContent: some View {
        DebugActionRow(
            title: "Mixed Queue (Mail + Text)",
            description: "Show an incoming email followed by a text message in the unified queue.",
            systemImage: "bell.badge.fill",
            color: .indigo,
            action: viewModel.triggerMixedNotificationsQueuePreview
        )

        debugDivider

        DebugActionRow(
            title: "Mixed Queue (Text + Photo)",
            description: "Show a text message followed by a photo attachment to verify bottom padding and row height.",
            systemImage: "photo.stack.fill",
            color: .teal,
            action: viewModel.triggerMixedAttachmentQueuePreview
        )

        debugDivider

        DebugActionRow(
            title: "Mixed Queue (Text + Audio)",
            description: "Show a text message followed by a playable audio voice note in the queue.",
            systemImage: "waveform.badge.plus",
            color: .orange,
            action: viewModel.triggerMixedAudioQueuePreview
        )

        debugDivider

        DebugActionRow(
            title: "Mixed Queue (Mail + Photo)",
            description: "Show an email followed by a photo attachment message in the queue.",
            systemImage: "envelope.and.arrow.trianglehead.branch.fill",
            color: .purple,
            action: viewModel.triggerMixedMailAndAttachmentQueuePreview
        )

        debugDivider

        DebugActionRow(
            title: "Messages Queue (3 Messages)",
            description: "Show three messages in sequence and animate the two-item queue transition.",
            systemImage: "message.badge.fill",
            color: .green,
            action: viewModel.triggerMessagesQueuePreview
        )
    }

    @ViewBuilder
    private var drivesPreviewContent: some View {
        DebugActionRow(
            title: "External Drive (Connected SSD)",
            description: "Show notification for connected external SSD with capacity.",
            systemImage: "externaldrive.fill",
            color: .blue,
            action: viewModel.triggerExternalDriveConnectedPreview
        )

        debugDivider

        DebugActionRow(
            title: "External Drive (USB Flash)",
            description: "Show notification for connected USB flash drive.",
            systemImage: "externaldrive.badge.wifi",
            color: .cyan,
            action: viewModel.triggerExternalDriveUSBPreview
        )

        debugDivider

        DebugActionRow(
            title: "External Drive (DMG Image)",
            description: "Show notification for mounted DMG disk image.",
            systemImage: "opticaldiscdrive.fill",
            color: .purple,
            action: viewModel.triggerExternalDriveDiskImagePreview
        )

        debugDivider

        DebugActionRow(
            title: "External Drive (Safely Ejected)",
            description: "Show notification for safely ejected drive.",
            systemImage: "checkmark.circle.fill",
            color: .orange,
            action: viewModel.triggerExternalDriveEjectedPreview
        )
    }

    private var utilitiesCard: some View {
        SettingsCard(title: "settings.debug.card.utilities") {
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
    let title: String
    let description: String
    let systemImage: String?
    let imageName: String?
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
        self.imageName = nil
        self.color = color
        self.buttonTitle = buttonTitle
        self.action = action
    }

    init(
        title: String,
        description: String,
        imageName: String,
        color: Color,
        buttonTitle: String = "Start",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.color = color
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(color.gradient)
                    )
            } else if let imageName {
                SettingsIconBadge(
                    imageName: imageName,
                    tint: color,
                    size: 30,
                    iconSize: 14,
                    cornerRadius: 10
                )
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(verbatim: description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 16)
            
            Button(action: action) {
                Text(verbatim: buttonTitle)
            }
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
