import SwiftUI

struct BluetoothSettingsView: View {
    @ObservedObject var settings: ConnectivitySettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    private var isBatteryStrokeLocked: Bool {
        applicationSettings.isDefaultActivityStrokeEnabled
    }

    private var isBatteryStrokeActive: Bool {
        settings.isBluetoothBatteryStrokeEnabled && applicationSettings.isDefaultActivityStrokeEnabled == false
    }

    private var bluetoothPreviewStrokeColor: Color {
        guard applicationSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        guard isBatteryStrokeActive,
              settings.bluetoothAppearanceStyle.supportsBatteryPresentation else {
            return .white.opacity(0.2)
        }

        return bluetoothBatteryColor(for: 82).opacity(0.3)
    }
    
    var body: some View {
        SettingsPageScrollView {
            bluetoothActivity
            bluetoothDuration
            bluetoothAppearance
        }
    }
    
    private var bluetoothActivity: some View {
        SettingsCard(title: "settings.bluetooth.card.activity") {
            SettingsToggleRow(
                title: "settings.bluetooth.temporaryActivity.title",
                description: "settings.bluetooth.temporaryActivity2.desc",
                imageName: "bluetooth.white",
                color: .blue,
                isOn: $settings.isBluetoothTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.bluetooth"
            )
        }
    }
    
    private var bluetoothDuration: some View {
        SettingsCard(title: "settings.bluetooth.card.duration") {
            SettingsSliderRow(
                title: "settings.bluetooth.duration.title",
                description: "settings.bluetooth.duration2.desc",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.bluetooth.duration",
                value: Binding(
                    get: { Double(settings.bluetoothTemporaryActivityDuration) },
                    set: { settings.bluetoothTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isBluetoothTemporaryActivityEnabled)
            .opacity(settings.isBluetoothTemporaryActivityEnabled ? 1 : 0.5)
        }
    }
    
    private var bluetoothAppearance: some View {
        SettingsCard(title: "settings.bluetooth.card.appearance") {
            CustomPicker(
                selection: $settings.bluetoothAppearanceStyle,
                options: Array(BluetoothAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "settings.bluetooth.style.headerTitle",
                headerDescription: "settings.bluetooth.style.headerDesc",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                bluetoothAppearancePickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.activities.temporary.bluetooth.style")

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.bluetooth.batteryIndicator.title",
                description: "settings.bluetooth.batteryIndicator2.desc",
                options: Array(BluetoothBatteryIndicatorStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.temporary.bluetooth.batteryIndicator",
                selection: $settings.bluetoothBatteryIndicatorStyle
            )

            Divider().opacity(0.6)
            
            SettingsStrokeToggleRow(
                title: "settings.bluetooth.batteryColoredStroke.title",
                description: "settings.bluetooth.batteryColoredStroke.desc",
                isOn: $settings.isBluetoothBatteryStrokeEnabled,
                accessibilityIdentifier: "settings.activities.temporary.bluetooth.batteryStroke"
            )
            .disabled(isBatteryStrokeLocked)
            .opacity(isBatteryStrokeLocked ? 0.5 : 1)
        }
    }
    
    @ViewBuilder
    private func bluetoothAppearancePickerContent(for style: BluetoothAppearanceStyle, isSelected: Bool) -> some View {
        switch style {
        case .compact:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(bluetoothPreviewStrokeColor, lineWidth: 1)
                    }
                HStack {
                    Image(systemName: "airpodsmax")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    if settings.bluetoothBatteryIndicatorStyle == .circle {
                        BluetoothBatteryIndicatorView(
                            batteryLevel: 82,
                            circleSize: 16,
                            circleLineWidth: 2.5,
                            usesTintedTrackStroke: isBatteryStrokeActive
                        )
                    } else {
                        Text("78%")
                            .foregroundStyle(.green.gradient)
                            .font(.system(size: 12))
                    }
                    
                }
                .padding(.horizontal, 7)
            }
            .frame(width: 160, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
            
        case .detailed:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(bluetoothPreviewStrokeColor, lineWidth: 1)
                    }
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "airpods.pro")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(verbatim: "Connected")
                                .lineLimit(1)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                            
                            Text("AirPods Pro")
                                .lineLimit(1)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        BluetoothBatteryIndicatorView(
                            batteryLevel: 78,
                            circleSize: 24,
                            circleLineWidth: 2.5,
                            usesTintedTrackStroke: isBatteryStrokeActive
                        )
                        Text(String(describing: 78))
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                        
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(width: 210, height: 50)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }

    private func bluetoothBatteryColor(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
}
