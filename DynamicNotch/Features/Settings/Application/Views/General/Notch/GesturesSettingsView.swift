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
        }
        .accessibilityIdentifier("settings.notch.gestures.root")
    }

    private var gesturesCard: some View {
        SettingsCard() {
            SettingsToggleRow(
                title: "Expand live activity",
                description: "Allow the selected notch gesture to open the expanded live activity layout when supported.",
                systemImage: "hand.tap.fill",
                color: .blue,
                isOn: $applicationSettings.isNotchTapToExpandEnabled,
                accessibilityIdentifier: "settings.notch.tapToExpand"
            )
            
            Divider()
                .opacity(0.6)
            
            SettingsMenuRow(
                title: "Expand gesture",
                description: "Choose whether expanded content opens on click, after holding the notch, or after hovering over it.",
                options: Array(NotchExpandInteraction.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.notch.expandInteraction",
                selection: $applicationSettings.notchExpandInteraction
            )
            
            Divider()
                .opacity(0.6)

            SettingsMenuRow(
                title: "Collapse gesture",
                description: "Choose whether expanded content closes on click or when the cursor leaves the notch.",
                options: Array(NotchCollapseInteraction.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.notch.collapseInteraction",
                selection: $applicationSettings.notchCollapseInteraction
            )
            
            Divider()
                .opacity(0.6)
            
            SettingsSliderRow(
                title: "Press and hold timing",
                description: "Adjust how quickly press-and-hold and hover expansion trigger.",
                range: ApplicationSettingsStore.notchPressHoldDurationRange,
                step: ApplicationSettingsStore.notchPressHoldDurationStep,
                fractionLength: 2,
                suffix: "s",
                accessibilityIdentifier: "settings.notch.pressHoldDuration",
                value: $applicationSettings.notchPressHoldDuration
            )
            .disabled(applicationSettings.notchExpandInteraction == .click)
            
            Divider()
                .opacity(0.6)
            
            SettingsToggleRow(
                title: "Hover haptic feedback",
                description: "Produce a soft haptic tick when the cursor enters the collapsed notch.",
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
                title: "Mouse drag gestures",
                description: "Use click-and-drag over the notch to preview dismiss and restore interactions.",
                systemImage: "cursorarrow.motionlines",
                color: .orange,
                isOn: $applicationSettings.isNotchMouseDragGesturesEnabled,
                accessibilityIdentifier: "settings.notch.mouseDragGestures"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Trackpad swipe gestures",
                description: "Use vertical two-finger scrolling over the notch to dismiss or restore the latest activity.",
                systemImage: "rectangle.and.hand.point.up.left.filled",
                color: .blue,
                isOn: $applicationSettings.isNotchTrackpadSwipeGesturesEnabled,
                accessibilityIdentifier: "settings.notch.trackpadSwipeGestures"
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
