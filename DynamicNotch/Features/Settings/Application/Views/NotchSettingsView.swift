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
    @ObservedObject var homePageSettings: HomePageSettingsStore

    
    var body: some View {
        SettingsPageScrollView {
            homePageCard
            prioritiesCard
            appearanceCard
            dynamicIslandAppearanceCard
            animationCard
            gesturesCard
        }
        .accessibilityIdentifier("settings.notch.root")
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
        SettingsCard(title: "Notch appearance") {
            CustomPicker(
                selection: $applicationSettings.notchBackgroundStyle,
                options: NotchBackgroundStyle.availableOptions,
                title: { $0.title },
                headerTitle: "Background",
                headerDescription: "Choose the background color used across the notch.",
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                backgroundPickerContent(for: style, isSelected: isSelected, isDynamicIsland: false)
            }
            .accessibilityIdentifier("settings.notch.backgroundStyle")
            
            if applicationSettings.notchBackgroundStyle == .liquidGlass {
                Divider().opacity(0.6)
                
                SettingsSliderRow(
                    title: "Liquid glass style",
                    description: "Adjust the style variant of the liquid glass background.",
                    range: Double(GeneralSettingsStorage.notchLiquidGlassVariantRange.lowerBound)...Double(GeneralSettingsStorage.notchLiquidGlassVariantRange.upperBound),
                    step: 1,
                    fractionLength: 0,
                    suffix: "",
                    accessibilityIdentifier: "settings.general.notchLiquidGlassVariant",
                    value: Binding(
                        get: { Double(applicationSettings.notchLiquidGlassVariant) },
                        set: { applicationSettings.notchLiquidGlassVariant = Int($0) }
                    )
                )
            }
            
            Divider().opacity(0.6)
            
            SettingsToggleRow(
                title: "Show notch stroke",
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
                description: "Adjust the thickness of the notch outline.",
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
                description: "Adjust the transparency of the notch outline.",
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
            
            SettingsSliderRow(
                title: "Notch width",
                description: "Fine-tune the notch width to better match your display cutout.",
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
    
    private var dynamicIslandAppearanceCard: some View {
        SettingsCard(title: "Dynamic Island appearance") {
            CustomPicker(
                selection: $applicationSettings.dynamicIslandBackgroundStyle,
                options: NotchBackgroundStyle.availableOptions,
                title: { $0.title },
                headerTitle: "Background",
                headerDescription: "Choose the background color used across the Dynamic Island.",
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                backgroundPickerContent(for: style, isSelected: isSelected, isDynamicIsland: true)
            }
            .accessibilityIdentifier("settings.dynamicIsland.backgroundStyle")
            
            if applicationSettings.dynamicIslandBackgroundStyle == .liquidGlass {
                Divider().opacity(0.6)
                
                SettingsSliderRow(
                    title: "Liquid glass style",
                    description: "Adjust the style variant of the liquid glass background.",
                    range: Double(GeneralSettingsStorage.dynamicIslandLiquidGlassVariantRange.lowerBound)...Double(GeneralSettingsStorage.dynamicIslandLiquidGlassVariantRange.upperBound),
                    step: 1,
                    fractionLength: 0,
                    suffix: "",
                    accessibilityIdentifier: "settings.general.dynamicIslandLiquidGlassVariant",
                    value: Binding(
                        get: { Double(applicationSettings.dynamicIslandLiquidGlassVariant) },
                        set: { applicationSettings.dynamicIslandLiquidGlassVariant = Int($0) }
                    )
                )
            }
            
            Divider().opacity(0.6)
            
            SettingsToggleRow(
                title: "Show Dynamic Island stroke",
                description: "Show a subtle outline that adapts to the active content color.",
                systemImage: "inset.filled.capsule",
                color: .black,
                isOn: $applicationSettings.isShowDynamicIslandStrokeEnabled,
                accessibilityIdentifier: "settings.general.showDynamicIslandStroke"
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
                isOn: $applicationSettings.isDynamicIslandDefaultActivityStrokeEnabled,
                accessibilityIdentifier: "settings.general.dynamicIslandDefaultActivityStroke"
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Stroke width",
                description: "Adjust the thickness of the Dynamic Island outline.",
                range: 1...3,
                step: 0.5,
                fractionLength: 1,
                suffix: "px",
                accessibilityIdentifier: "settings.general.dynamicIslandStrokeWidth",
                value: $applicationSettings.dynamicIslandStrokeWidth
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "Stroke opacity",
                description: "Adjust the transparency of the Dynamic Island outline.",
                range: 0...100,
                step: 5,
                fractionLength: 0,
                suffix: "%",
                accessibilityIdentifier: "settings.general.dynamicIslandStrokeOpacity",
                value: Binding(
                    get: { applicationSettings.dynamicIslandStrokeOpacity * 100 },
                    set: { applicationSettings.dynamicIslandStrokeOpacity = $0 / 100 }
                )
            )
            
            SettingsSliderRow(
                title: "Dynamic Island width",
                description: "Fine-tune the Dynamic Island width to better match your preferences.",
                range: -32...16,
                step: 1,
                fractionLength: 0,
                suffix: "px",
                accessibilityIdentifier: "settings.general.dynamicIslandWidth",
                value: Binding(
                    get: { Double(applicationSettings.dynamicIslandWidth) },
                    set: { applicationSettings.dynamicIslandWidth = Int($0.rounded()) }
                )
            )
            
            SettingsSliderRow(
                title: "Dynamic Island height",
                description: "Fine-tune the Dynamic Island height to better match your preferences.",
                range: -4...4,
                step: 1,
                fractionLength: 0,
                suffix: "px",
                accessibilityIdentifier: "settings.general.dynamicIslandHeight",
                value: Binding(
                    get: { Double(applicationSettings.dynamicIslandHeight) },
                    set: { applicationSettings.dynamicIslandHeight = Int($0.rounded()) }
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
            
        case .ultraThickMaterial:
            ZStack {
                shape
                    .fill(Color.white.opacity(0.05))
                
                shape
                    .fill(.ultraThinMaterial)
                    .overlay {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.10),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay {
                        shape
                            .stroke(strokeColor, lineWidth: strokeWidth)
                    }
            }
            
        case .liquidGlass:
            let variant = isDynamicIsland ? applicationSettings.dynamicIslandLiquidGlassVariant : applicationSettings.notchLiquidGlassVariant
            LiquidGlassBackground(
                variant: LiquidGlassVariant.clamped(variant),
                cornerRadius: isDynamicIsland ? 15 : 6
            ) {
                Color.clear
            }
            .clipShape(shape)
            .overlay {
                shape
                    .stroke(strokeColor, lineWidth: strokeWidth)
            }
        }
    }
    
    private func previewStrokeColor(isDynamicIsland: Bool) -> Color {
        let isShowStroke = isDynamicIsland ? applicationSettings.isShowDynamicIslandStrokeEnabled : applicationSettings.isShowNotchStrokeEnabled
        guard isShowStroke else {
            return .clear
        }
        
        let isDefaultActivityStroke = isDynamicIsland ? applicationSettings.isDynamicIslandDefaultActivityStrokeEnabled : applicationSettings.isDefaultActivityStrokeEnabled
        let strokeOpacity = isDynamicIsland ? applicationSettings.dynamicIslandStrokeOpacity : applicationSettings.notchStrokeOpacity
        
        let baseColor: Color = isDefaultActivityStroke ?
            .white.opacity(0.2) :
            .green.opacity(0.3)
        return baseColor.opacity(strokeOpacity)
    }
    
    private func previewStrokeWidth(isDynamicIsland: Bool) -> CGFloat {
        let isShowStroke = isDynamicIsland ? applicationSettings.isShowDynamicIslandStrokeEnabled : applicationSettings.isShowNotchStrokeEnabled
        let strokeWidth = isDynamicIsland ? applicationSettings.dynamicIslandStrokeWidth : applicationSettings.notchStrokeWidth
        return isShowStroke ? CGFloat(strokeWidth) : 0
    }
    
    private var homePageCard: some View {
        SettingsCard(title: "Home Page") {
            SettingsToggleRow(
                title: "Home Page live activity",
                description: "Show the Home Page in the notch.",
                systemImage: "house.fill",
                color: .black,
                isOn: $homePageSettings.isHomePageLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.homePage"
            )
            
            Divider().opacity(0.6)
            
            List {
                ForEach(homePageSettings.homePageOrder, id: \.self) { page in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 14))
                        
                        SettingsIconBadge(
                            systemImage: page.icon,
                            tint: page.tint,
                            size: 30,
                            iconSize: 14,
                            cornerRadius: 9
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(page.title)
                            Text(page.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { !homePageSettings.homePageDisabled.contains(page) },
                            set: { isEnabled in
                                if isEnabled {
                                    homePageSettings.homePageDisabled.remove(page)
                                } else {
                                    homePageSettings.homePageDisabled.insert(page)
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.gray.opacity(0.15))
                }
                .onMove { from, to in
                    homePageSettings.homePageOrder.move(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(height: CGFloat(homePageSettings.homePageOrder.count) * 52)
            .disabled(!homePageSettings.isHomePageLiveActivityEnabled)
            .opacity(homePageSettings.isHomePageLiveActivityEnabled ? 1.0 : 0.5)
            
            Divider().opacity(0.6)
            
            Text(LocalizedStringKey("Drag to reorder pages. Disabled pages will be hidden."))
                .font(.caption)
                .foregroundColor(.gray)
                .opacity(homePageSettings.isHomePageLiveActivityEnabled ? 1.0 : 0.5)
        }
    }
}
