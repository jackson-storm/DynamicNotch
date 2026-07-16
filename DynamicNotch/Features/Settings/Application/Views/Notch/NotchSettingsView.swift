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
    @Binding var availableDisplays: [NotchDisplayOption]

    
    var body: some View {
        SettingsPageScrollView {
            displayCard
            prioritiesCard
            appearanceCard
            animationCard
            gesturesCard
        }
        .accessibilityIdentifier("settings.notch.root")
        .onAppear(perform: refreshAvailableDisplays)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refreshAvailableDisplays()
        }
    }
    
    private var prioritiesCard: some View {
        SettingsCard(title: "settings.notch.priorities.title") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(NotchContentPriority.configurableKeys.enumerated()), id: \.element.id) { index, priorityKey in
                    priorityRow(for: priorityKey)
                    
                    if index < NotchContentPriority.configurableKeys.count - 1 {
                        Divider()
                            .opacity(0.6)
                            .padding(.leading, 43)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().opacity(0.6)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.notch.priorities.customOrder.title")
                    Text("settings.notch.priorities.customOrder.description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                
                Button {
                    applicationSettings.resetNotchContentPriorities()
                } label: {
                    Text("settings.notch.priorities.reset")
                }
                .disabled(applicationSettings.notchContentPriorityOverrides.isEmpty)
            }
            .modifier(SettingsAccessibilityModifier(identifier: "settings.notch.priorities.reset"))
        }
    }
    
    private var appearanceCard: some View {
        SettingsCard(title: "Appearance") {
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
                color: .purple,
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
    
    private var animationCard: some View {
        SettingsCard(title: "Animation") {
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
    
    private var gesturesCard: some View {
        SettingsCard(title: "Gestures") {
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
                title: "Swipe up to dismiss",
                description: "Allow gestures to hide the currently visible live or temporary activity.",
                systemImage: "arrow.up.circle.fill",
                color: .red,
                isOn: $applicationSettings.isNotchSwipeDismissEnabled,
                accessibilityIdentifier: "settings.notch.swipeDismiss"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Swipe down to restore",
                description: "Allow gestures to bring back the most recently dismissed activity.",
                systemImage: "arrow.down.circle.fill",
                color: .red,
                isOn: $applicationSettings.isNotchSwipeRestoreEnabled,
                accessibilityIdentifier: "settings.notch.swipeRestore"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Close notch on window focus",
                description: "Hides the active content with a balloon animation when the target application becomes active.",
                systemImage: "xmark.circle.fill",
                color: .red,
                isOn: $applicationSettings.isCloseAtFocusLiveActivityEnabled,
                accessibilityIdentifier: "settings.notch.closeAtFocus"
            )
        }
    }
    
    private func priorityRow(for priorityKey: NotchContentPriority.Key) -> some View {
        HStack(alignment: .center, spacing: 12) {
            priorityIcon(for: priorityKey)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(priorityKey.titleKey)
                
                Text(priorityDefaultText(for: priorityKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 12)
            
            Stepper(
                value: priorityBinding(for: priorityKey),
                in: NotchContentPriority.priorityRange
            ) {
                Text("\(applicationSettings.notchContentPriority(for: priorityKey))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 22, alignment: .trailing)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 1)
        .modifier(SettingsAccessibilityModifier(identifier: "settings.notch.priority.\(priorityKey.rawValue)"))
    }
    
    private func priorityBinding(for priorityKey: NotchContentPriority.Key) -> Binding<Int> {
        Binding(
            get: {
                applicationSettings.notchContentPriority(for: priorityKey)
            },
            set: { newValue in
                applicationSettings.setNotchContentPriority(newValue, for: priorityKey)
            }
        )
    }
    
    private func priorityDefaultText(for priorityKey: NotchContentPriority.Key) -> String {
        applicationSettings.appLanguage.locale.dnFormat(
            "settings.notch.priorities.row.default",
            fallback: "Default %lld",
            Int64(priorityKey.defaultValue)
        )
    }
    
    @ViewBuilder
    private func priorityIcon(for priorityPreset: NotchContentPriority.Key) -> some View {
        SettingsIconBadge(
            systemImage: priorityPreset.image,
            tint: priorityPreset.color,
            size: 30,
            iconSize: 14,
            cornerRadius: 9
        )
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
    
    private var displayCard: some View {
        SettingsCard() {
            CustomPicker(
                selection: $applicationSettings.displayLocation,
                options: Array(NotchDisplayLocation.allCases),
                title: { $0.title },
                headerTitle: "Display",
                headerDescription: "Choose which display Dynamic Notch should use.",
                symbolName: { $0.symbolName }
            )
            .accessibilityIdentifier("settings.general.displayLocation")
            
            Divider()
                .opacity(0.6)
            
            if applicationSettings.displayLocation == .specific {
                SpecificDisplayPicker(
                    applicationSettings: applicationSettings,
                    availableDisplays: $availableDisplays
                )
                
                Divider()
                    .opacity(0.6)
                
                SettingsToggleRow(
                    title: "settings.general.display.autoSwitch.title",
                    description: "settings.general.display.autoSwitch.description",
                    systemImage: "arrow.triangle.branch",
                    color: .blue,
                    isOn: $applicationSettings.isDisplayAutoSwitchEnabled,
                    accessibilityIdentifier: "settings.general.displayAutoSwitch"
                )
                
                if let unavailableDescriptionKey {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "display.trianglebadge.exclamationmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.orange)
                        
                        Text(unavailableDescriptionKey)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                    .opacity(0.6)
            }
            
            SettingsToggleRow(
                title: "Hide live activity in full-screen mode",
                description: "Automatically hide live activity while the selected display is showing a full-screen space.",
                systemImage: "arrow.up.left.and.arrow.down.right",
                color: .blue,
                isOn: $applicationSettings.isNotchHiddenInFullscreenEnabled,
                accessibilityIdentifier: "settings.general.hideNotchInFullscreen"
            )
        }
    }

    private var unavailableDescriptionKey: LocalizedStringKey? {
        guard applicationSettings.displayLocation == .specific,
              let selectedSpecificDisplayUUID,
              !availableDisplays.contains(where: { $0.displayUUID == selectedSpecificDisplayUUID }) else {
            return nil
        }
        if applicationSettings.isDisplayAutoSwitchEnabled {
            return "settings.general.display.unavailable.autoSwitchEnabled"
        }
        return "settings.general.display.unavailable.autoSwitchDisabled"
    }
    
    private var selectedSpecificDisplayUUID: String? {
        applicationSettings.preferredDisplayUUID.isEmpty ? nil : applicationSettings.preferredDisplayUUID
    }

    private func refreshAvailableDisplays() {
        availableDisplays = NSScreen.availableNotchDisplays()
        applicationSettings.syncPreferredDisplayMetadata()
    }
    
    private func localized(_ key: String, fallback: String? = nil) -> String {
        applicationSettings.appLanguage.locale.dn(key, fallback: fallback)
    }
}

private struct SpecificDisplayPicker: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @Binding var availableDisplays: [NotchDisplayOption]
    
    private var selectedSpecificDisplayUUID: String? {
        applicationSettings.preferredDisplayUUID.isEmpty ? nil : applicationSettings.preferredDisplayUUID
    }
    
    private var specificDisplayOptions: [NotchDisplayOption] {
        guard let selectedSpecificDisplayUUID else {
            return availableDisplays
        }
        
        if availableDisplays.contains(where: { $0.displayUUID == selectedSpecificDisplayUUID }) {
            return availableDisplays
        }
        
        return availableDisplays + [
            NotchDisplayOption.unavailable(
                displayUUID: selectedSpecificDisplayUUID,
                name: unavailableDisplayName
            )
        ]
    }
    
    private var selectedSpecificDisplay: NotchDisplayOption {
        specificDisplayOptions.first(where: { $0.displayUUID == selectedSpecificDisplayUUID }) ??
        availableDisplays.first ??
        NotchDisplayOption.unavailable(
            displayUUID: selectedSpecificDisplayUUID ?? "unknown",
            name: unavailableDisplayName
        )
    }
    
    private var unavailableDisplayName: String {
        applicationSettings.preferredDisplayName.isEmpty ?
        localized(
            "settings.general.display.unavailable.placeholder",
            fallback: "Unavailable display"
        ) :
        applicationSettings.preferredDisplayName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.general.display.specificPicker.title")
                    Text("settings.general.display.specificPicker.description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 12)
                
                Text(verbatim: selectedSpecificDisplay.name)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 116, maximum: 152), spacing: 12)],
                spacing: 12
            ) {
                ForEach(specificDisplayOptions) { display in
                    specificDisplayCard(for: display)
                }
            }
        }
    }
    
    private func specificDisplayCard(for display: NotchDisplayOption) -> some View {
        let isSelected = selectedSpecificDisplayUUID == display.displayUUID
        
        return Button {
            applicationSettings.selectPreferredDisplay(display)
            refreshAvailableDisplays()
        } label: {
            let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
            
            VStack(spacing: 8) {
                VStack(spacing: 8) {
                    Image(systemName: display.symbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                    
                    Text(verbatim: display.name)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(
                    shape
                        .fill(
                            isSelected ?
                            Color.accentColor.opacity(0.08) :
                                Color.gray.opacity(0.08)
                        )
                )
                .overlay(
                    shape
                        .stroke(
                            isSelected ? Color.accentColor.opacity(0.9) : Color.gray.opacity(0.12),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .contentShape(shape)
                
                if !display.isAvailable {
                    Text("settings.general.display.badge.unavailable")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.orange)
                    
                } else if display.isBuiltIn {
                    Text("settings.general.display.badge.builtin")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    
                } else if display.isMain {
                    Text("settings.general.display.badge.main")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    
                } else {
                    Text("settings.general.display.badge.external")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!display.isAvailable)
        .accessibilityIdentifier("settings.general.display.specific.\(display.displayUUID)")
    }
    
    private func refreshAvailableDisplays() {
        availableDisplays = NSScreen.availableNotchDisplays()
        applicationSettings.syncPreferredDisplayMetadata()
    }
    
    private func localized(_ key: String, fallback: String? = nil) -> String {
        applicationSettings.appLanguage.locale.dn(key, fallback: fallback)
    }
}
