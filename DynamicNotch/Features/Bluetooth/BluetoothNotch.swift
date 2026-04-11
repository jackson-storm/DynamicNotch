import SwiftUI

struct BluetoothConnectedNotchContent: NotchContentProtocol {
    let id = "bluetooth.connected"
    let bluetoothViewModel: BluetoothViewModel
    let settings: ConnectivitySettingsStore
    let applicationSettings: ApplicationSettingsStore
    
    var offsetXTransition: CGFloat { -90 }
    var strokeColor: Color {
        guard settings.bluetoothAppearanceStyle.supportsBatteryPresentation,
              settings.isBluetoothBatteryStrokeEnabled,
              applicationSettings.isDefaultActivityStrokeEnabled == false,
              let batteryLevel = bluetoothViewModel.batteryLevel else {
            return .white.opacity(0.2)
        }

        return batteryStrokeColor(for: batteryLevel).opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat

        switch settings.bluetoothAppearanceStyle {
        case .device:
            width = settings.bluetoothBatteryIndicatorStyle == .circle ? 80 : 90
        case .detailed:
            width = settings.bluetoothBatteryIndicatorStyle == .circle ? 180 : 180
        }

        return .init(width: baseWidth + CGFloat(width), height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            BluetoothConnectedNotchView(
                bluetoothViewModel: bluetoothViewModel,
                settings: settings,
                applicationSettings: applicationSettings
            )
        )
    }

    private func batteryStrokeColor(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
}

private struct BluetoothConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    private var appearanceStyle: BluetoothAppearanceStyle {
        settings.bluetoothAppearanceStyle
    }

    private var batteryIndicatorStyle: BluetoothBatteryIndicatorStyle {
        settings.bluetoothBatteryIndicatorStyle
    }

    private var isBatteryStrokeActive: Bool {
        settings.isBluetoothBatteryStrokeEnabled && applicationSettings.isDefaultActivityStrokeEnabled == false
    }
    
    var body: some View {
        HStack {
            leftContent
            Spacer()
            rightContent
        }
        .padding(.horizontal, 14.scaled(by: scale))
        .font(.system(size: 14))
    }
    
    @ViewBuilder
    private var leftContent: some View {
        switch appearanceStyle {
        case .device:
            Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.8))
                .transition(.blurAndFade.animation(.spring(duration: 0.4)))

        case .detailed:
            MarqueeText(
                $bluetoothViewModel.deviceName,
                font: .system(size: 14),
                nsFont: .body,
                textColor: .white.opacity(0.8),
                backgroundColor: .clear,
                minDuration: 0.5,
                frameWidth: 90
            )
            .lineLimit(1)
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .trailing)))
        }
    }
    
    @ViewBuilder
    private var rightContent: some View {
        switch appearanceStyle {
        case .device:
            HStack(spacing: 8) {
                BluetoothBatteryIndicatorView(
                    batteryLevel: bluetoothViewModel.batteryLevel,
                    indicatorStyle: batteryIndicatorStyle,
                    circleSize: 18,
                    circleLineWidth: 3,
                    usesTintedTrackStroke: isBatteryStrokeActive
                )
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .leading)))

        case .detailed:
            HStack(spacing: 6) {
                BluetoothBatteryIndicatorView(
                    batteryLevel: bluetoothViewModel.batteryLevel,
                    indicatorStyle: batteryIndicatorStyle,
                    circleSize: 18,
                    circleLineWidth: 3,
                    usesTintedTrackStroke: isBatteryStrokeActive
                )

                Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .leading)))
        }
    }
}

struct BluetoothBatteryIndicatorView: View {
    let batteryLevel: Int?
    let indicatorStyle: BluetoothBatteryIndicatorStyle
    let circleSize: CGFloat
    let circleLineWidth: CGFloat
    var usesTintedTrackStroke: Bool = false

    private var clampedLevel: Int? {
        batteryLevel.map { max(0, min(100, $0)) }
    }

    private func tint(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }

    private func progress(for level: Int) -> CGFloat {
        CGFloat(level) / 100
    }

    private func trackStrokeColor(for level: Int) -> Color {
        guard usesTintedTrackStroke else {
            return .white.opacity(0.16)
        }

        return tint(for: level).opacity(0.22)
    }

    var body: some View {
        if let clampedLevel {
            switch indicatorStyle {
            case .percent:
                Text("\(clampedLevel)%")
                    .foregroundStyle(tint(for: clampedLevel).gradient)

            case .circle:
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.04))

                    Circle()
                        .stroke(trackStrokeColor(for: clampedLevel), lineWidth: circleLineWidth)

                    Circle()
                        .trim(from: 0, to: progress(for: clampedLevel))
                        .stroke(
                            tint(for: clampedLevel).gradient,
                            style: StrokeStyle(lineWidth: circleLineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: tint(for: clampedLevel).opacity(0.35), radius: 5, y: 0)
                }
                .frame(width: circleSize, height: circleSize)
            }
        } else {
            Text("---")
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
