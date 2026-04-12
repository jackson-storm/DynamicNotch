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
        SettingsCard(title: "Bluetooth activity") {
            SettingsToggleRow(
                title: "Bluetooth temporary activity",
                description: "Show a temporary activity when a Bluetooth accessory connects.",
                imageName: "bluetooth.white",
                color: .blue,
                isOn: $settings.isBluetoothTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.bluetooth"
            )
        }
    }
    
    private var bluetoothDuration: some View {
        SettingsCard(title: "Bluetooth duration") {
            SettingsSliderRow(
                title: "Bluetooth duration",
                description: "Choose how long the Bluetooth connection notification stays visible.",
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
        SettingsCard(title: "Bluetooth appearance") {
            CustomPicker(
                selection: $settings.bluetoothAppearanceStyle,
                options: Array(BluetoothAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "Bluetooth style",
                headerDescription: "Choose between a device-focused layout or full device details.",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                bluetoothAppearancePickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.activities.temporary.bluetooth.style")

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "Battery indicator",
                description: "Choose whether Bluetooth battery information is shown as a percentage or a circular indicator.",
                options: Array(BluetoothBatteryIndicatorStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.temporary.bluetooth.batteryIndicator",
                selection: $settings.bluetoothBatteryIndicatorStyle
            )

            Divider().opacity(0.6)
            
            SettingsStrokeToggleRow(
                title: "Battery-colored stroke",
                description: "Tint Bluetooth battery styles using the current battery level color.",
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
        case .device:
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

                    BluetoothBatteryIndicatorView(
                        batteryLevel: 82,
                        indicatorStyle: settings.bluetoothBatteryIndicatorStyle,
                        circleSize: 16,
                        circleLineWidth: 2.5,
                        usesTintedTrackStroke: isBatteryStrokeActive
                    )
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
                    Text("AirPods Max")
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Spacer()

                    BluetoothBatteryIndicatorView(
                        batteryLevel: 82,
                        indicatorStyle: settings.bluetoothBatteryIndicatorStyle,
                        circleSize: 16,
                        circleLineWidth: 2.5,
                        usesTintedTrackStroke: isBatteryStrokeActive
                    )
                    
                    Image(systemName: "airpodsmax")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.trailing, 7)
                .padding(.leading, 10)
            }
            .frame(width: 210, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }

    private func bluetoothBatteryColor(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
}
