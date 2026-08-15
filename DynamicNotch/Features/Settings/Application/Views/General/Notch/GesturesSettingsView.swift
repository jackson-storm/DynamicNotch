//
//  GesturesSettingsView.swift
//  DynamicNotch
//

import SwiftUI

struct GesturesSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            gesturesCard
            gestureToggleCard
        }
        .accessibilityIdentifier("settings.notch.gestures.root")
    }

    private var gesturesCard: some View {
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
    
    private var gestureToggleCard: some View {
        SettingsCard {
            SettingsToggleRow(
                title: "settings.notch.gestures.hoverHaptic.title",
                description: "settings.notch.gestures.hoverHaptic.desc",
                systemImage: "waveform",
                color: .red,
                isOn: $applicationSettings.isNotchHoverHapticEnabled,
                accessibilityIdentifier: "settings.notch.hoverHaptic"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.notch.gestures.swipeDismissAndRestore.title",
                description: "settings.notch.gestures.swipeDismissAndRestore.subtitle",
                systemImage: "arrow.up.and.down.circle.fill",
                color: .red,
                isOn: Binding(
                    get: { applicationSettings.isNotchSwipeDismissEnabled && applicationSettings.isNotchSwipeRestoreEnabled },
                    set: { newValue in
                        applicationSettings.isNotchSwipeDismissEnabled = newValue
                        applicationSettings.isNotchSwipeRestoreEnabled = newValue
                    }
                ),
                accessibilityIdentifier: "settings.notch.swipeDismissAndRestore"
            )
        }
    }
}
