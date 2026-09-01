import SwiftUI

struct ScreenCaptureSettingsView: View {
    @ObservedObject var settings: ScreenRecordingSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            screenCaptureActivity
            screenshotDuration
            saveLocationSection
            screenRecordingAppearance
        }
    }
    
    private func localized(_ key: String, fallback: String? = nil) -> String {
        appearanceSettings.appLanguage.locale.dn(key, fallback: fallback ?? key)
    }
    
    private var screenCaptureActivity: some View {
        SettingsCard(title: "settings.screenRecording.card.activity") {
            SettingsToggleRow(
                title: "settings.screenRecording.recordingActivity.title",
                description: "settings.screenRecording.recordingActivity.desc",
                systemImage: "record.circle.fill",
                color: .red,
                isOn: $settings.isScreenRecordingLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.screenRecording"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.screenRecording.screenshotActivity.title",
                description: "settings.screenRecording.screenshotActivity.desc",
                systemImage: "viewfinder",
                color: .gray,
                isOn: $settings.isScreenshotActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.screenshot"
            )
        }
    }

    private var screenRecordingAppearance: some View {
        SettingsCard(title: "settings.screenRecording.card.appearance") {
            CustomPicker(
                selection: $settings.screenRecordingStyle,
                options: Array(ScreenRecordingStyle.allCases),
                title: { $0.title },
                headerTitle: "settings.screenRecording.style.headerTitle",
                headerDescription: "settings.screenRecording.style.headerDesc",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                screenRecordingAppearancePickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.activities.live.screenRecording.style")
            
            Divider().opacity(0.6)

            SettingsStrokeToggleRow(
                title: "settings.notch.defaultStrokeColor.title",
                description: "settings.notch.defaultStrokeColor.desc",
                isOn: $settings.isScreenRecordingDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.screenRecording.defaultStroke"
            )
            .disabled(!settings.isScreenRecordingLiveActivityEnabled)
            .opacity(settings.isScreenRecordingLiveActivityEnabled ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private func screenRecordingAppearancePickerContent(for style: ScreenRecordingStyle, isSelected: Bool) -> some View {
        switch style {
        case .compact:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(screenRecordingPreviewStrokeColor, lineWidth: 1)
                    }
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            .frame(width: 120, height: 28)
            .scaleEffect(isSelected ? 1 : 0.97)

        case .detailed:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(screenRecordingPreviewStrokeColor, lineWidth: 1)
                    }
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    
                    Spacer()
                    
                    Text("00:10")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.red)
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
            }
            .frame(width: 140, height: 28)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }

    private var screenRecordingPreviewStrokeColor: Color {
        guard appearanceSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        if appearanceSettings.isDefaultActivityStrokeEnabled || settings.isScreenRecordingDefaultStrokeEnabled {
            return .white.opacity(0.2)
        }

        return .red.opacity(0.3)
    }
    
    private var saveLocationSection: some View {
        SettingsCard(title: "settings.screenRecording.card.saveLocation") {
            SettingsChoiceRow(
                title: localized("settings.screenRecording.screenshotsFolder.title"),
                description: localized("settings.screenRecording.screenshotsFolder.desc"),
                statusText: formattedPath(settings.screenshotSavePath),
                statusColor: .secondary,
                chooseButtonTitle: settings.screenshotSavePath.isEmpty ? localized("settings.common.choose") : localized("settings.common.change"),
                onChoose: {
                    selectFolder { path in
                        settings.screenshotSavePath = path
                    }
                },
                onReset: !settings.screenshotSavePath.isEmpty ? {
                    settings.screenshotSavePath = ""
                } : nil,
                accessibilityIdentifier: "settings.screenshot.savePath"
            )
            
            Divider().opacity(0.6)

            SettingsChoiceRow(
                title: localized("settings.screenRecording.recordingsFolder.title"),
                description: localized("settings.screenRecording.recordingsFolder.desc"),
                statusText: formattedPath(settings.screenRecordingSavePath),
                statusColor: .secondary,
                chooseButtonTitle: settings.screenRecordingSavePath.isEmpty ? localized("settings.common.choose") : localized("settings.common.change"),
                onChoose: {
                    selectFolder { path in
                        settings.screenRecordingSavePath = path
                    }
                },
                onReset: !settings.screenRecordingSavePath.isEmpty ? {
                    settings.screenRecordingSavePath = ""
                } : nil,
                accessibilityIdentifier: "settings.screenRecording.savePath"
            )
        }
    }
    
    private var screenshotDuration: some View {
        SettingsCard(title: "settings.screenRecording.card.duration") {
            SettingsToggleRow(
                title: "settings.screenRecording.autoDismiss.title",
                description: "settings.screenRecording.autoDismiss.desc",
                systemImage: "timer",
                color: .orange,
                isOn: $settings.isScreenshotAutoHideEnabled,
                accessibilityIdentifier: "settings.screenshot.autoHideEnabled"
            )
            .disabled(!settings.isScreenshotActivityEnabled)
            .opacity(settings.isScreenshotActivityEnabled ? 1 : 0.5)
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "settings.screenRecording.duration.title",
                description: "settings.screenRecording.duration.desc",
                range: 3...8,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.screenshot.duration",
                value: Binding(
                    get: { Double(settings.screenshotTemporaryActivityDuration) },
                    set: { settings.screenshotTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isScreenshotActivityEnabled || !settings.isScreenshotAutoHideEnabled)
            .opacity((settings.isScreenshotActivityEnabled && settings.isScreenshotAutoHideEnabled) ? 1 : 0.5)
        }
    }
    
    private func formattedPath(_ path: String) -> String {
        if path.isEmpty {
            let desktopPath = (FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path) ?? "~/Desktop"
            let format = localized("settings.screenRecording.desktopFormat")
            return String(format: format, desktopPath)
        }
        let expanded = (path as NSString).expandingTildeInPath
        let abbreviated = (expanded as NSString).abbreviatingWithTildeInPath
        return abbreviated
    }

    private func selectFolder(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = localized("settings.common.select")
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let path = url.path
                let abbreviated = (path as NSString).abbreviatingWithTildeInPath
                completion(abbreviated)
            }
        }
    }
}
