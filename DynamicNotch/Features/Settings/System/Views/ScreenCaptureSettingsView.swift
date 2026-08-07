import SwiftUI

struct ScreenCaptureSettingsView: View {
    @ObservedObject var settings: ScreenRecordingSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            screenCaptureActivity
            saveLocationSection
            screenshotDuration
        }
    }
    
    private func localized(_ key: String, fallback: String? = nil) -> String {
        appearanceSettings.appLanguage.locale.dn(key, fallback: fallback ?? key)
    }
    
    private var screenCaptureActivity: some View {
        SettingsCard(title: "Screen Capture activity") {
            SettingsToggleRow(
                title: "Screen Recording live activity",
                description: "Show a red recording indicator in the notch while screen capture is active.",
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
                title: "Screenshot activity",
                description: "Show temporary activity with screenshot preview in the notch and hide default macOS corner thumbnail.",
                systemImage: "viewfinder",
                color: .gray,
                isOn: $settings.isScreenshotActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.screenshot"
            )
        }
    }
    
    private var saveLocationSection: some View {
        SettingsCard(title: LocalizedStringKey(localized("Save Locations", fallback: "Save Locations"))) {
            SettingsChoiceRow(
                title: localized("Screenshots folder", fallback: "Screenshots folder"),
                description: localized("Choose where captured screenshots will be saved.", fallback: "Choose where captured screenshots will be saved."),
                statusText: formattedPath(settings.screenshotSavePath),
                statusColor: .secondary,
                chooseButtonTitle: settings.screenshotSavePath.isEmpty ? localized("Choose", fallback: "Choose") : localized("Change", fallback: "Change"),
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
                title: localized("Screen recordings folder", fallback: "Screen recordings folder"),
                description: localized("Choose where screen recordings will be saved.", fallback: "Choose where screen recordings will be saved."),
                statusText: formattedPath(settings.screenRecordingSavePath),
                statusColor: .secondary,
                chooseButtonTitle: settings.screenRecordingSavePath.isEmpty ? localized("Choose", fallback: "Choose") : localized("Change", fallback: "Change"),
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
        SettingsCard(title: "Screenshot duration") {
            SettingsToggleRow(
                title: "Auto-dismiss timer",
                description: "Automatically hide the screenshot preview when the duration timer expires.",
                systemImage: "timer",
                color: .orange,
                isOn: $settings.isScreenshotAutoHideEnabled,
                accessibilityIdentifier: "settings.screenshot.autoHideEnabled"
            )
            .disabled(!settings.isScreenshotActivityEnabled)
            .opacity(settings.isScreenshotActivityEnabled ? 1 : 0.5)
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Screenshot duration",
                description: "Choose how long the screenshot preview stays visible in the notch.",
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
            let format = localized("Desktop (%@)", fallback: "Desktop (%@)")
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
        panel.prompt = localized("Select", fallback: "Select")
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let path = url.path
                let abbreviated = (path as NSString).abbreviatingWithTildeInPath
                completion(abbreviated)
            }
        }
    }
}
