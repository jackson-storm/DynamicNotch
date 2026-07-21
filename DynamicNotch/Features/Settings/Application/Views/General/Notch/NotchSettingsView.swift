//
//  NotchSettingsView.swift
//  DynamicNotch
//

import SwiftUI
internal import AppKit

struct NotchSettingsView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @Binding var availableDisplays: [NotchDisplayOption]

    var body: some View {
        SettingsPageScrollView {
            appearanceCard
            otherSettings
        }
        .accessibilityIdentifier("settings.notch.root")
        .onAppear(perform: refreshAvailableDisplays)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refreshAvailableDisplays()
        }
    }
    
    private var appearanceCard: some View {
        SettingsCard() {
            SettingsToggleRow(
                title: "Show stroke",
                description: "Show a subtle outline that adapts to the active content color.",
                systemImage: "inset.filled.capsule",
                color: .black,
                stroke: true,
                isOn: $applicationSettings.isShowNotchStrokeEnabled,
                accessibilityIdentifier: "settings.general.showNotchStroke"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Use default activity stroke color",
                description: "Apply the standard white stroke to supported activities instead of feature accent colors.",
                systemImage: "paintbrush.pointed.fill",
                color: LinearGradient.purpleGradient,
                isOn: $applicationSettings.isDefaultActivityStrokeEnabled,
                accessibilityIdentifier: "settings.general.defaultActivityStroke"
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Stroke width",
                description: "Adjust the thickness of the outline.",
                range: 1...3,
                step: 0.5,
                fractionLength: 1,
                suffix: "px",
                accessibilityIdentifier: "settings.general.notchStrokeWidth",
                value: $applicationSettings.notchStrokeWidth
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Stroke opacity",
                description: "Adjust the transparency of the outline.",
                range: 0...100,
                step: 5,
                fractionLength: 0,
                suffix: "%",
                accessibilityIdentifier: "settings.general.notchStrokeOpacity",
                value: Binding(
                    get: { applicationSettings.notchStrokeOpacity * 100 },
                    set: { applicationSettings.notchStrokeOpacity = $0 / 100 }
                )
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Width",
                description: "Fine-tune the width of the notch or Dynamic Island.",
                range: -32...16,
                step: 1,
                fractionLength: 0,
                suffix: "px",
                accessibilityIdentifier: "settings.general.notchWidth",
                value: Binding(
                    get: { Double(applicationSettings.notchWidth) },
                    set: { applicationSettings.notchWidth = Int($0.rounded()) }
                )
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Height",
                description: "Fine-tune the height of the notch or Dynamic Island.",
                range: -4...4,
                step: 1,
                fractionLength: 0,
                suffix: "px",
                accessibilityIdentifier: "settings.general.notchHeight",
                value: Binding(
                    get: { Double(applicationSettings.notchHeight) },
                    set: { applicationSettings.notchHeight = Int($0.rounded()) }
                )
            )
        }
    }
    
    private var otherSettings: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "settings.notch.priorities.title",
                description: "settings.notch.priorities.subtitle",
                systemImage: "list.bullet",
                color: .red,
                accessibilityIdentifier: "settings.notch.priorities",
                position: .first,
                value: SettingsSubPage.activityPriorities
            )
            
            SettingsNavigationRowView(
                title: "settings.notch.display.title",
                description: "settings.notch.display.subtitle",
                systemImage: "display.2",
                color: .black,
                stroke: true,
                accessibilityIdentifier: "settings.notch.display",
                position: .middle,
                value: SettingsSubPage.notchDisplay
            )
            
            SettingsNavigationRowView(
                title: "Animation",
                description: "settings.notch.animation.subtitle",
                systemImage: "sparkles",
                color: LinearGradient.cyanGradient,
                accessibilityIdentifier: "settings.notch.animation",
                position: .middle,
                value: SettingsSubPage.notchAnimation
            )
            
            SettingsNavigationRowView(
                title: "Gestures",
                description: "settings.notch.gestures.subtitle",
                systemImage: "hand.draw.badge.ellipsis.fill",
                color: LinearGradient.orangeGradient,
                accessibilityIdentifier: "settings.notch.gestures",
                position: .last,
                value: SettingsSubPage.gestures
            )
        }
    }
    
    private func refreshAvailableDisplays() {
        availableDisplays = NSScreen.availableNotchDisplays()
        applicationSettings.syncPreferredDisplayMetadata()
    }
}
