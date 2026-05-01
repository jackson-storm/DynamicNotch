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
            prioritiesCard
            appearanceCard
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
                backgroundPickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.notch.backgroundStyle")

            Divider().opacity(0.6)

            SettingsToggleRow(
                title: "Show notch stroke",
                description: "Show a subtle outline that adapts to the active content color.",
                systemImage: "square.on.square.squareshape.controlhandles",
                color: .green,
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
                description: "Choose whether expanded content opens on click or after holding the notch.",
                options: Array(NotchExpandInteraction.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.notch.expandInteraction",
                selection: $applicationSettings.notchExpandInteraction
            )

            Divider()
                .opacity(0.6)

            SettingsSliderRow(
                title: "Press and hold timing",
                description: "Adjust how quickly the notch press peaks and hold-to-expand triggers.",
                range: ApplicationSettingsStore.notchPressHoldDurationRange,
                step: ApplicationSettingsStore.notchPressHoldDurationStep,
                fractionLength: 2,
                suffix: "s",
                accessibilityIdentifier: "settings.notch.pressHoldDuration",
                value: $applicationSettings.notchPressHoldDuration
            )

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
                color: .mint,
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
                color: .teal,
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
    private func priorityIcon(for priorityKey: NotchContentPriority.Key) -> some View {
        let sidebarSection = priorityKey.sidebarSection

        if let imageName = sidebarSection.imageName {
            SettingsIconBadge(
                imageName: imageName,
                tint: sidebarSection.tint,
                size: 30,
                iconSize: 14,
                cornerRadius: 9
            )
        } else {
            SettingsIconBadge(
                systemImage: sidebarSection.systemImage,
                tint: sidebarSection.tint,
                size: 30,
                iconSize: 14,
                cornerRadius: 9
            )
        }
    }

    @ViewBuilder
    private func backgroundPickerContent(for style: NotchBackgroundStyle, isSelected: Bool) -> some View {
        ZStack {
            previewCapsule(for: style)
                .frame(width: 116, height: 30)
        }
        .environment(\.colorScheme, .dark)
        .scaleEffect(isSelected ? 1 : 0.97)
    }

    @ViewBuilder
    private func previewCapsule(for style: NotchBackgroundStyle) -> some View {
        switch style {
        case .black:
            Capsule()
                .fill(.black)
                .overlay {
                    Capsule()
                        .stroke(previewStrokeColor, lineWidth: previewStrokeWidth)
                }

        case .ultraThickMaterial:
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.05))

                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
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
                        Capsule()
                            .stroke(previewStrokeColor, lineWidth: previewStrokeWidth)
                    }
            }

        case .liquidGlass:
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(previewStrokeColor, lineWidth: previewStrokeWidth)
                    }
            }
        }
    }

    private var previewStrokeColor: Color {
        guard applicationSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        return applicationSettings.isDefaultActivityStrokeEnabled ?
            .white.opacity(0.2) :
            .green.opacity(0.3)
    }

    private var previewStrokeWidth: CGFloat {
        applicationSettings.isShowNotchStrokeEnabled ? CGFloat(applicationSettings.notchStrokeWidth) : 0
    }
}

private extension NotchContentPriority.Key {
    var titleKey: LocalizedStringKey {
        switch self {
        case .focus:
            "settings.notch.priorities.row.focus"
        case .hotspot:
            "settings.notch.priorities.row.hotspot"
        case .download:
            "settings.notch.priorities.row.downloads"
        case .trayActive:
            "settings.notch.priorities.row.trayActive"
        case .nowPlaying:
            "settings.notch.priorities.row.nowPlaying"
        case .timer:
            "settings.notch.priorities.row.timer"
        case .screenRecording:
            "settings.notch.priorities.row.screenRecording"
        }
    }

    var sidebarSection: SettingsRootViewModel.Section {
        switch self {
        case .focus:
                .focus
        case .hotspot:
                .network
        case .download:
                .downloads
        case .trayActive:
                .drop
        case .nowPlaying:
                .nowPlaying
        case .timer:
                .timer
        case .screenRecording:
                .screenRecording
        }
    }
}
