import SwiftUI

struct ScreenCaptureSettingsView: View {
    @ObservedObject var settings: ScreenRecordingSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            screenCaptureActivity
            screenshotDuration
        }
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
}
