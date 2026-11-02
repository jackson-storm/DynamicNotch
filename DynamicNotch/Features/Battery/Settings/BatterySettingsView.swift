import SwiftUI

struct BatterySettingsView: View {
    private enum BatteryNotificationPreviewKind {
        case low
        case full
    }
    
    @ObservedObject var batterySettings: BatterySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    @Environment(\.locale) private var locale
    
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
        SettingsCard(title: "settings.battery.card.activity") {
            SettingsToggleRow(
                title: "settings.battery.charging.title",
                description: "settings.battery.charging.desc",
                systemImage: "bolt.fill",
                color: .green,
                isOn: $batterySettings.isChargerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.charger"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.battery.lowPower2.title",
                description: "settings.battery.lowPower2.desc",
                systemImage: "battery.25",
                color: .red,
                isOn: $batterySettings.isLowPowerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.lowPower"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.battery.fullyCharged.title",
                description: "settings.battery.fullyCharged.desc",
                systemImage: "battery.100",
                color: .green,
                isOn: $batterySettings.isFullPowerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.fullPower"
            )
            
        }
    }
    
    private var batteryDuration: some View {
        SettingsCard(title: "settings.battery.card.duration") {
            SettingsSliderRow(
                title: "settings.battery.chargingDuration.title",
                description: "settings.battery.chargingDuration.desc",
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
                title: "settings.battery.lowBatteryDuration.title",
                description: "settings.battery.lowPowerDuration.desc",
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
                title: "settings.battery.fullBatteryDuration.title",
                description: "settings.battery.fullPowerDuration.desc",
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
        SettingsCard(title: "settings.battery.card.lowBattery") {
            CustomPicker(
                selection: $batterySettings.lowPowerStyle,
                options: Array(BatteryNotificationStyle.allCases),
                title: { $0.title },
                headerTitle: "settings.battery.lowBatteryStyle.headerTitle",
                headerDescription: "settings.battery.lowBatteryStyle.headerDesc",
                itemHeight: 100,
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
            
            SettingsToggleRow(
                title: "settings.battery.lowBatterySound.title",
                description: "settings.battery.lowBatterySound2.desc",
                systemImage: "speaker.wave.2.fill",
                color: .pink,
                isOn: $batterySettings.lowBatterySound,
                accessibilityIdentifier: "settings.activities.lowBatterySound"
            )
            
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "settings.battery.lowPowerThreshold.title",
                description: "settings.battery.lowBatteryThreshold.desc",
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
        SettingsCard(title: "settings.battery.card.fullBattery") {
            CustomPicker(
                selection: $batterySettings.fullPowerStyle,
                options: Array(BatteryNotificationStyle.allCases),
                title: { $0.title },
                headerTitle: "settings.battery.fullBatteryStyle.headerTitle",
                headerDescription: "settings.battery.fullBatteryStyle.headerDesc",
                itemHeight: 100,
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
            
            SettingsToggleRow(
                title: "settings.battery.fullBatterySound.title",
                description: "settings.battery.fullBatterySound2.desc",
                systemImage: "speaker.wave.2.fill",
                color: .pink,
                isOn: $batterySettings.fullBatterySound,
                accessibilityIdentifier: "settings.activities.fullBatterySound"
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "settings.battery.fullChargeThreshold.title",
                description: "settings.battery.fullChargeThreshold.desc",
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
                        .stroke(batteryPreviewStrokeColor(for: kind), lineWidth: 1)
                }
            
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    batteryStandardTitle(for: kind)
                    batteryStandardDescription(for: kind)
                }
                
                Spacer()
                
                if kind == .low {
                    lowBatteryStandardIndicator
                } else {
                    fullBatteryStandardIndicator
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 15)
        }
        .frame(width: 230, height: 60)
        .scaleEffect(isSelected ? 1 : 0.97)
    }
    
    private func batteryCompactPickerContent(for kind: BatteryNotificationPreviewKind, isSelected: Bool) -> some View {
        let lowBatteryLevel = batterySettings.lowPowerNotificationThreshold
        let fullBatteryLevel = batterySettings.fullPowerNotificationThreshold
        let batteryLevel = kind == .low ? lowBatteryLevel : fullBatteryLevel
        let tint: Color = kind == .low ? .red : .green
        
        return ZStack {
            Capsule()
                .fill(.black)
                .overlay {
                    Capsule()
                        .stroke(batteryPreviewStrokeColor(for: kind), lineWidth: 1)
                }
            
            HStack {
                if kind == .low {
                    Text(locale.dn("notch.battery.low", fallback: "Low Battery"))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                } else {
                    Text(locale.dn("notch.battery.full", fallback: "Full Battery"))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
                
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
        .frame(width: 200, height: 30)
        .scaleEffect(isSelected ? 1 : 0.97)
    }
    
    @ViewBuilder
    private func batteryStandardTitle(for kind: BatteryNotificationPreviewKind) -> some View {
        let lowBatteryLevel = batterySettings.lowPowerNotificationThreshold
        let fullBatteryLevel = batterySettings.fullPowerNotificationThreshold
        let batteryLevel = kind == .low ? lowBatteryLevel : fullBatteryLevel
        
        HStack(spacing: 5) {
            if kind == .low {
                Text(locale.dn("notch.battery.detail.lowTitle", fallback: "Battery Low"))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
            } else {
                Text(locale.dn("notch.battery.detail.fullTitle", fallback: "Full Battery"))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
            }
            Text("\(batteryLevel)%")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(kind == .low ? .red : .green)
        }
    }
    
    @ViewBuilder
    private func batteryStandardDescription(for kind: BatteryNotificationPreviewKind) -> some View {
        if kind == .low {
            Text(locale.dn("notch.battery.detail.turnOnLowPower", fallback: "Turn on Low Power Mode or it\nis recommended to charge it."))
                .font(.system(size: 8.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(2)
        } else {
            Text(locale.dn("notch.battery.detail.fullyCharged", fallback: "Your Mac is fully charged."))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
        }
    }
    
    private var lowBatteryStandardIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.red.opacity(0.2))
                .frame(width: 55, height: 35)
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.red.opacity(0.4))
                    .frame(width: 35, height: 20)
                
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.red.opacity(0.4))
                    .frame(width: 3, height: 7)
            }
            
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.red.gradient)
                .frame(width: 7, height: 11)
                .offset(x: -12)
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.red.opacity(0.9), lineWidth: 1.2)
                .frame(width: 18, height: 20)
                .offset(x: -12)
        }
    }
    
    private var fullBatteryStandardIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.green.opacity(0.2))
                .frame(width: 55, height: 35)
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.green.opacity(0.4))
                    .frame(width: 35, height: 20)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.green.gradient)
                            .frame(width: 24, height: 11)
                    }
                
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.green.opacity(0.4))
                    .frame(width: 3, height: 7)
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
    
    private func batteryPreviewStrokeColor(for kind: BatteryNotificationPreviewKind) -> Color {
        guard appearanceSettings.isShowNotchStrokeEnabled else {
            return .clear
        }
        
        return kind == .low ? .red.opacity(0.3) : .green.opacity(0.3)
    }
}
