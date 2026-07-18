//
//  AnimationSettingsView.swift
//  DynamicNotch
//

import SwiftUI

struct AnimationSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            animationCard
        }
        .accessibilityIdentifier("settings.notch.animation.root")
    }

    private var animationCard: some View {
        SettingsCard() {
            CustomPicker(
                selection: $applicationSettings.notchAnimationPreset,
                options: Array(NotchAnimationPreset.allCases),
                title: { $0.title },
                headerTitle: "Animation speed",
                headerDescription: "Set a global motion parameter that controls the speed of the animation.",
                symbolName: { $0.symbolName }
            )
            .accessibilityIdentifier("settings.general.animationPreset")
        }
    }
}
