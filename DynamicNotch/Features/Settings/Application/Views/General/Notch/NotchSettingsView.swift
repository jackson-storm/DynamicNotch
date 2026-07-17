//
//  NotchSettingsView.swift
//  DynamicNotch
//

import SwiftUI
internal import AppKit

struct NotchSettingsView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @Binding var availableDisplays: [NotchDisplayOption]

    var body: some View {
        SettingsPageScrollView {
            appearanceCard
            otherSettings
        }
        .accessibilityIdentifier("settings.notch.root")
        .onAppear(perform: refreshAvailableDisplays)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refreshAvailableDisplays()
        }
    }
    
    private var appearanceCard: some View {
        SettingsCard() {
            CustomPicker(
                selection: $applicationSettings.notchBackgroundStyle,
                options: NotchBackgroundStyle.availableOptions,
                title: { $0.title },
                headerTitle: "Background",
                headerDescription: "Choose the background color used across the notch and Dynamic Island.",
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                backgroundPickerContent(for: style, isSelected: isSelected, isDynamicIsland: true)
            }
            Divider().opacity(0.6)
            
            SettingsToggleRow(
                title: "Show stroke",
                description: "Show a subtle outline that adapts to the active content color.",
                systemImage: "inset.filled.capsule",
                color: .black,
                stroke: true,
                isOn: $applicationSettings.isShowNotchStrokeEnabled,
                accessibilityIdentifier: "settings.general.showNotchStroke"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Use default activity stroke color",
                description: "Apply the standard white stroke to supported activities instead of feature accent colors.",
                systemImage: "paintbrush.pointed.fill",
                color: LinearGradient.purpleGradient,
                isOn: $applicationSettings.isDefaultActivityStrokeEnabled,
                accessibilityIdentifier: "settings.general.defaultActivityStroke"
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Stroke width",
                description: "Adjust the thickness of the outline.",
                range: 1...3,
                step: 0.5,
                fractionLength: 1,
                suffix: "px",
                accessibilityIdentifier: "settings.general.notchStrokeWidth",
                value: $applicationSettings.notchStrokeWidth
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Stroke opacity",
                description: "Adjust the transparency of the outline.",
                range: 0...100,
                step: 5,
                fractionLength: 0,
                suffix: "%",
                accessibilityIdentifier: "settings.general.notchStrokeOpacity",
                value: Binding(
                    get: { applicationSettings.notchStrokeOpacity * 100 },
                    set: { applicationSettings.notchStrokeOpacity = $0 / 100 }
                )
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Width",
                description: "Fine-tune the width of the notch or Dynamic Island.",
                range: -32...16,
                step: 1,
                fractionLength: 0,
                suffix: "px",
                accessibilityIdentifier: "settings.general.notchWidth",
                value: Binding(
                    get: { Double(applicationSettings.notchWidth) },
                    set: { applicationSettings.notchWidth = Int($0.rounded()) }
                )
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Height",
                description: "Fine-tune the height of the notch or Dynamic Island.",
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
    
    private var otherSettings: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "settings.notch.priorities.title",
                description: "settings.notch.priorities.subtitle",
                systemImage: "list.bullet",
                color: LinearGradient.blueGradient,
                accessibilityIdentifier: "settings.notch.priorities",
                position: .first,
                value: SettingsSubPage.activityPriorities
            )
            
            SettingsNavigationRowView(
                title: "settings.notch.display.title",
                description: "settings.notch.display.subtitle",
                systemImage: "display.2",
                color: .black,
                stroke: true,
                accessibilityIdentifier: "settings.notch.display",
                position: .middle,
                value: SettingsSubPage.notchDisplay
            )
            
            SettingsNavigationRowView(
                title: "Animation",
                description: "settings.notch.animation.subtitle",
                systemImage: "sparkles",
                color: LinearGradient.cyanGradient,
                accessibilityIdentifier: "settings.notch.animation",
                position: .middle,
                value: SettingsSubPage.notchAnimation
            )
            
            SettingsNavigationRowView(
                title: "Gestures",
                description: "settings.notch.gestures.subtitle",
                systemImage: "hand.draw.badge.ellipsis.fill",
                color: LinearGradient.orangeGradient,
                accessibilityIdentifier: "settings.notch.gestures",
                position: .last,
                value: SettingsSubPage.gestures
            )
        }
    }
    
    @ViewBuilder
    private func backgroundPickerContent(for style: NotchBackgroundStyle, isSelected: Bool, isDynamicIsland: Bool) -> some View {
        ZStack(alignment: isDynamicIsland ? .center : .top) {
            previewShape(for: style, isDynamicIsland: isDynamicIsland)
                .frame(width: 116, height: isDynamicIsland ? 30 : 26)
        }
        .frame(maxHeight: .infinity, alignment: isDynamicIsland ? .center : .top)
        .environment(\.colorScheme, .dark)
        .scaleEffect(isSelected ? 1 : 0.97)
    }
    
    @ViewBuilder
    private func previewShape(for style: NotchBackgroundStyle, isDynamicIsland: Bool) -> some View {
        let shape = isDynamicIsland ? AnyShape(Capsule()) : AnyShape(NotchShape(topCornerRadius: 6, bottomCornerRadius: 12))
        let strokeColor = previewStrokeColor(isDynamicIsland: isDynamicIsland)
        let strokeWidth = previewStrokeWidth(isDynamicIsland: isDynamicIsland)
        
        switch style {
        case .black:
            shape
                .fill(.black)
                .overlay {
                    shape
                        .stroke(strokeColor, lineWidth: strokeWidth)
                }
            
        case .liquidGlass:
            LiquidGlassBackground(
                variant: LiquidGlassVariant.clamped(7),
                cornerRadius: isDynamicIsland ? 15 : 12,
                hideTopBorder: !isDynamicIsland
            ) {
                ZStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color.black.opacity(0.65), location: 0.0),
                            .init(color: Color.black.opacity(0.65), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: Color.black.opacity(0.65), location: 0.20),
                            .init(color: Color.black.opacity(0.65), location: 0.80),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .padding(.top, isDynamicIsland ? 0 : 10)
            .offset(y: isDynamicIsland ? 0 : -10)
            .clipShape(shape)
            .overlay {
                shape
                    .stroke(strokeColor, lineWidth: strokeWidth)
            }
        }
    }
    
    private func previewStrokeColor(isDynamicIsland: Bool) -> Color {
        let isShowStroke = applicationSettings.isShowNotchStrokeEnabled
        guard isShowStroke else {
            return .clear
        }
        
        let isDefaultActivityStroke = applicationSettings.isDefaultActivityStrokeEnabled
        let strokeOpacity = applicationSettings.notchStrokeOpacity
        
        let baseColor: Color = isDefaultActivityStroke ?
            .white.opacity(0.2) :
            .green.opacity(0.3)
        return baseColor.opacity(strokeOpacity)
    }
    
    private func previewStrokeWidth(isDynamicIsland: Bool) -> CGFloat {
        let isShowStroke = applicationSettings.isShowNotchStrokeEnabled
        let strokeWidth = applicationSettings.notchStrokeWidth
        return isShowStroke ? CGFloat(strokeWidth) : 0
    }

    private func refreshAvailableDisplays() {
        availableDisplays = NSScreen.availableNotchDisplays()
        applicationSettings.syncPreferredDisplayMetadata()
    }
}
