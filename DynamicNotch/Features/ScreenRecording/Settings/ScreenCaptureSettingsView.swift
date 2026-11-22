import SwiftUI

struct ScreenCaptureSettingsView: View {
    @ObservedObject var settings: ScreenRecordingSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            screenCaptureActivity
            screenshotDuration
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
        appearanceSettings.isShowNotchStrokeEnabled ? .red.opacity(0.3) : .clear
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
