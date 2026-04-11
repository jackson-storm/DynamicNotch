import SwiftUI

struct BatterySettingsView: View {
    private enum BatteryNotificationPreviewKind {
        case low
        case full
    }

    @ObservedObject var batterySettings: BatterySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    var body: some View {
        SettingsPageScrollView {
            batteryActivity
            batteryDuration
            lowBattery
            fullBattery
        }
    }

    private var batteryActivity: some View {
        SettingsCard(
            title: "Battery activity",
            subtitle: "Control charging, low battery, and full battery notifications."
        ) {
            SettingsToggleRow(
                title: "Charging",
                description: "Show a temporary activity when your Mac starts charging.",
                systemImage: "bolt.fill",
                color: .green,
                isOn: $batterySettings.isChargerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.charger"
            )

            Divider()
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "Low Power",
                description: "Show a warning when Low Power Mode is enabled or the battery is critically low.",
                systemImage: "battery.25",
                color: .green,
                isOn: $batterySettings.isLowPowerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.lowPower"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "Fully Charged",
                description: "Show a temporary activity when the battery reaches the selected full charge level.",
                systemImage: "battery.100",
                color: .green,
                isOn: $batterySettings.isFullPowerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.fullPower"
            )
        }
    }

    private var batteryDuration: some View {
        SettingsCard(
            title: "Battery duration",
            subtitle: "Control how long each battery notification stays visible."
        ) {
            SettingsSliderRow(
                title: "Charging duration",
                description: "Choose how long the charging notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.charger.duration",
                value: Binding(
                    get: { Double(batterySettings.chargerTemporaryActivityDuration) },
                    set: { batterySettings.chargerTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!batterySettings.isChargerTemporaryActivityEnabled)
            .opacity(batterySettings.isChargerTemporaryActivityEnabled ? 1 : 0.5)

            Divider().opacity(0.6)

            SettingsSliderRow(
                title: "Low battery duration",
                description: "Choose how long the low battery notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.lowPower.duration",
                value: Binding(
                    get: { Double(batterySettings.lowPowerTemporaryActivityDuration) },
                    set: { batterySettings.lowPowerTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!batterySettings.isLowPowerTemporaryActivityEnabled)
            .opacity(batterySettings.isLowPowerTemporaryActivityEnabled ? 1 : 0.5)

            Divider().opacity(0.6)

            SettingsSliderRow(
                title: "Full battery duration",
                description: "Choose how long the full battery notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.fullPower.duration",
                value: Binding(
                    get: { Double(batterySettings.fullPowerTemporaryActivityDuration) },
                    set: { batterySettings.fullPowerTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!batterySettings.isFullPowerTemporaryActivityEnabled)
            .opacity(batterySettings.isFullPowerTemporaryActivityEnabled ? 1 : 0.5)
        }
    }

    private var lowBattery: some View {
        SettingsCard(
            title: "Low battery",
            subtitle: "Choose when the alert appears and how the low battery notification looks."
        ) {
            CustomPicker(
                selection: $batterySettings.lowPowerStyle,
                options: Array(BatteryNotificationStyle.allCases),
                title: { $0.title },
                headerTitle: "Low battery style",
                headerDescription: "Choose whether the alert uses the current detailed card or a compact charging-like layout.",
                itemHeight: 82,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                batteryStylePickerContent(
                    for: style,
                    kind: .low,
                    isSelected: isSelected
                )
            }
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Low battery threshold",
                description: "Choose the battery percentage that triggers the low battery notification.",
                range: Double(BatterySettingsStore.lowPowerThresholdRange.lowerBound)...Double(BatterySettingsStore.lowPowerThresholdRange.upperBound),
                step: 1,
                fractionLength: 0,
                suffix: "%",
                accessibilityIdentifier: "settings.activities.temporary.lowPower.threshold",
                value: Binding(
                    get: { Double(batterySettings.lowPowerNotificationThreshold) },
                    set: { batterySettings.lowPowerNotificationThreshold = Int($0.rounded()) }
                )
            )
        }
    }

    private var fullBattery: some View {
        SettingsCard(
            title: "Full battery",
            subtitle: "Choose when the alert appears and how the full battery notification looks."
        ) {
            CustomPicker(
                selection: $batterySettings.fullPowerStyle,
                options: Array(BatteryNotificationStyle.allCases),
                title: { $0.title },
                headerTitle: "Full battery style",
                headerDescription: "Choose whether the alert uses the current detailed card or a compact charging-like layout.",
                itemHeight: 82,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                batteryStylePickerContent(
                    for: style,
                    kind: .full,
                    isSelected: isSelected
                )
            }
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Full charge threshold",
                description: "Choose the battery percentage that triggers the full charge notification.",
                range: Double(BatterySettingsStore.fullPowerThresholdRange.lowerBound)...Double(BatterySettingsStore.fullPowerThresholdRange.upperBound),
                step: 1,
                fractionLength: 0,
                suffix: "%",
                accessibilityIdentifier: "settings.activities.temporary.fullPower.threshold",
                value: Binding(
                    get: { Double(batterySettings.fullPowerNotificationThreshold) },
                    set: { batterySettings.fullPowerNotificationThreshold = Int($0.rounded()) }
                )
            )
        }
    }

    @ViewBuilder
    private func batteryStylePickerContent(for style: BatteryNotificationStyle, kind: BatteryNotificationPreviewKind, isSelected: Bool) -> some View {
        switch style {
        case .standard:
            batteryStandardPickerContent(for: kind, isSelected: isSelected)

        case .compact:
            batteryCompactPickerContent(for: kind, isSelected: isSelected)
        }
    }

    private func batteryStandardPickerContent(for kind: BatteryNotificationPreviewKind, isSelected: Bool) -> some View {
        ZStack {
            Capsule()
                .fill(.black)
                .overlay {
                    Capsule()
                        .stroke(kind == .low ? .red.opacity(0.3) : .green.opacity(0.3), lineWidth: 1)
                }

            VStack {
                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: kind == .low ? 2 : 3) {
                        batteryStandardTitle(for: kind)
                        batteryStandardDescription(for: kind)
                    }

                    Spacer(minLength: 8)

                    if kind == .low {
                        lowBatteryStandardIndicator
                    } else {
                        fullBatteryStandardIndicator
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 10)
                .padding(.bottom, kind == .full ? 12 : 10)
            }
        }
        .frame(height: kind == .low ? 56 : 52)
        .scaleEffect(isSelected ? 1 : 0.97)
    }

    private func batteryCompactPickerContent(for kind: BatteryNotificationPreviewKind, isSelected: Bool) -> some View {
        let title = kind == .low ? "Low Battery" : "Full Battery"
        let batteryLevel = kind == .low ? 20 : 100
        let tint: Color = kind == .low ? .red : .green

        return ZStack {
            Capsule()
                .fill(.black)
                .overlay {
                    Capsule()
                        .stroke(kind == .low ? .red.opacity(0.3) : .green.opacity(0.3), lineWidth: 1)
                }

            HStack {
                Text(verbatim: title)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    Text("\(batteryLevel)%")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(tint)

                    batteryCompactIndicator(
                        fillFraction: CGFloat(batteryLevel) / 100,
                        tint: tint
                    )
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 30)
        .scaleEffect(isSelected ? 1 : 0.97)
    }

    @ViewBuilder
    private func batteryStandardTitle(for kind: BatteryNotificationPreviewKind) -> some View {
        HStack(spacing: 5) {
            Text(verbatim: kind == .low ? "Battery Low" : "Full Battery")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)

            Text(kind == .low ? "20%" : "100%")
                .font(.system(size: kind == .low ? 10 : 10.5, weight: .semibold))
                .foregroundStyle(kind == .low ? .red : .green)
        }
    }

    @ViewBuilder
    private func batteryStandardDescription(for kind: BatteryNotificationPreviewKind) -> some View {
        if kind == .low {
            Text(verbatim: "Turn on Low Power Mode or it\nis recommended to charge it.")
                .font(.system(size: 8.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(2)
        } else {
            Text(verbatim: "Your Mac is fully charged.")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
        }
    }

    private var lowBatteryStandardIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.red.opacity(0.2))
                .frame(width: 44, height: 26)

            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.red.opacity(0.4))
                    .frame(width: 26, height: 16)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.red.opacity(0.4))
                    .frame(width: 2, height: 5)
            }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.red.gradient)
                .frame(width: 5, height: 9)
                .offset(x: -9)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.red.opacity(0.9), lineWidth: 1.2)
                .frame(width: 16, height: 18)
                .offset(x: -9)
        }
    }

    private var fullBatteryStandardIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.green.opacity(0.2))
                .frame(width: 44, height: 26)

            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.green.opacity(0.4))
                    .frame(width: 28, height: 16)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .fill(Color.green.gradient)
                            .frame(width: 20, height: 8)
                    }

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.green.opacity(0.4))
                    .frame(width: 2, height: 5)
            }
        }
    }

    private func batteryCompactIndicator(fillFraction: CGFloat, tint: Color) -> some View {
        HStack(spacing: 1.5) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.3))

                Rectangle()
                    .fill(tint.gradient)
                    .frame(width: 28 * fillFraction)
            }
            .frame(width: 28, height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(fillFraction >= 1 ? tint.gradient : tint.opacity(0.3).gradient)
                .frame(width: 2, height: 6)
        }
    }
}
