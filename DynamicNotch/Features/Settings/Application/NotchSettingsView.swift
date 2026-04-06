//
//  NotchSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/3/26.
//

import SwiftUI

struct NotchSettingsView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            appearanceCard
            animationCard
            temporaryActivitiesCard
        }
        .accessibilityIdentifier("settings.notch.root")
    }

    private var appearanceCard: some View {
        SettingsCard(
            title: "Notch appearance",
            subtitle: "Fine-tune the notch frame and stroke so it better matches your hardware."
        ) {
            VStack(alignment: .leading) {
                SettingsNotchPreview(
                    width: 370,
                    height: 38,
                    previewHeight: 80,
                    topCornerRadius: 9,
                    bottomCornerRadius: 13,
                    showsStroke: applicationSettings.isShowNotchStrokeEnabled,
                    strokeColor: applicationSettings.isDefaultActivityStrokeEnabled ? .white.opacity(0.2) : .green.opacity(0.3),
                    strokeWidth: CGFloat(applicationSettings.notchStrokeWidth),
                    lightBackgroundImage: Image("backgroundLight"),
                    darkBackgroundImage: Image("backgroundDark")
                ) {
                    ChargerNotchView(powerService: powerService)
                }

                SettingsToggleRow(
                    title: "Show notch stroke",
                    description: "Show a subtle outline that adapts to the active content color.",
                    systemImage: "square.on.square.squareshape.controlhandles",
                    color: .green,
                    isOn: $applicationSettings.isShowNotchStrokeEnabled,
                    accessibilityIdentifier: "settings.general.showNotchStroke"
                )

                Divider().opacity(0.6)

                SettingsToggleRow(
                    title: "Use default activity stroke color",
                    description: "Apply the standard white stroke to supported activities instead of feature accent colors.",
                    systemImage: "paintbrush.pointed.fill",
                    color: .purple,
                    isOn: $applicationSettings.isDefaultActivityStrokeEnabled,
                    accessibilityIdentifier: "settings.general.defaultActivityStroke"
                )

                Divider().opacity(0.6)

                SettingsToggleRow(
                    title: "Resize feedback",
                    description: "Show temporary size hints while adjusting the notch width or height.",
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    color: .red,
                    isOn: $applicationSettings.isNotchSizeTemporaryActivityEnabled,
                    accessibilityIdentifier: "settings.activities.temporary.notchSize"
                )

                Divider().opacity(0.6)

                SettingsSliderRow(
                    title: "Stroke width",
                    description: "Adjust the thickness of the notch outline.",
                    range: 1...3,
                    step: 0.5,
                    fractionLength: 1,
                    suffix: "px",
                    accessibilityIdentifier: "settings.general.notchStrokeWidth",
                    value: $applicationSettings.notchStrokeWidth
                )

                SettingsSliderRow(
                    title: "Notch width",
                    description: "Fine-tune the notch width to better match your display cutout.",
                    range: -8...8,
                    step: 1,
                    fractionLength: 0,
                    suffix: "px",
                    accessibilityIdentifier: "settings.general.notchWidth",
                    value: Binding(
                        get: { Double(applicationSettings.notchWidth) },
                        set: { applicationSettings.notchWidth = Int($0.rounded()) }
                    )
                )

                SettingsSliderRow(
                    title: "Notch height",
                    description: "Fine-tune the notch height to better match your display cutout.",
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
    }

    private var animationCard: some View {
        SettingsCard(
            title: "Animation",
            subtitle: "Choose one global motion preset for notch transitions, expansion, and visibility."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                CustomPicker(
                    selection: $applicationSettings.notchAnimationPreset,
                    options: Array(NotchAnimationPreset.allCases),
                    title: { $0.title },
                    symbolName: { $0.symbolName }
                )
                .accessibilityIdentifier("settings.general.animationPreset")
            }
        }
    }

    private var temporaryActivitiesCard: some View {
        SettingsCard(
            title: "Temporary activities",
            subtitle: "Control how long short-lived notifications stay visible."
        ) {
            SettingsSliderRow(
                title: "Notification duration",
                description: "Scale the duration of temporary activities across HUD, battery, connectivity, and resize feedback.",
                range: 0.5...2,
                step: 0.25,
                fractionLength: 2,
                suffix: "x",
                accessibilityIdentifier: "settings.general.temporaryDurationScale",
                value: $applicationSettings.temporaryActivityDurationScale
            )
        }
    }
}
