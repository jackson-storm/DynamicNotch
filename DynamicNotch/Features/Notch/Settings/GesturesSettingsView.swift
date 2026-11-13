//
//  GesturesSettingsView.swift
//  DynamicNotch
//

import SwiftUI

struct GesturesSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            gesturesToggleCard
            gesturesCard
        }
        .accessibilityIdentifier("settings.notch.gestures.root")
    }
    
    private var gesturesToggleCard: some View {
        SettingsCard() {
            SettingsToggleRow(
                title: "settings.notch.gestures.expandActivity.title",
                description: "settings.notch.gestures.expandActivity.desc",
                systemImage: "hand.tap.fill",
                color: .blue,
                isOn: $applicationSettings.isNotchTapToExpandEnabled,
                accessibilityIdentifier: "settings.notch.tapToExpand"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.notch.gestures.hoverHaptic.title",
                description: "settings.notch.gestures.hoverHaptic.desc",
                systemImage: "waveform",
                color: .red,
                isOn: $applicationSettings.isNotchHoverHapticEnabled,
                accessibilityIdentifier: "settings.notch.hoverHaptic"
            )
        }
    }
    
    private var gesturesCard: some View {
        SettingsCard {
            SettingsMenuRow(
                title: "settings.notch.gestures.expandGesture.title",
                description: "settings.notch.gestures.expandGesture.desc",
                options: Array(NotchExpandInteraction.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.notch.expandInteraction",
                selection: $applicationSettings.notchExpandInteraction
            )
            
            Divider()
                .opacity(0.6)
            
            SettingsMenuRow(
                title: "settings.notch.gestures.collapseGesture.title",
                description: "settings.notch.gestures.collapseGesture.desc",
                options: Array(NotchCollapseInteraction.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.notch.collapseInteraction",
                selection: $applicationSettings.notchCollapseInteraction
            )
            
            Divider()
                .opacity(0.6)
            
            SettingsSliderRow(
                title: "settings.notch.gestures.pressHoldTiming.title",
                description: "settings.notch.gestures.pressHoldTiming.desc",
                range: ApplicationSettingsStore.notchPressHoldDurationRange,
                step: ApplicationSettingsStore.notchPressHoldDurationStep,
                fractionLength: 2,
                suffix: "s",
                accessibilityIdentifier: "settings.notch.pressHoldDuration",
                value: $applicationSettings.notchPressHoldDuration
            )
            .disabled(applicationSettings.notchExpandInteraction == .click)
        }
    }
}
