//
//  DisplaySettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/13/26.
//

import SwiftUI

struct DisplaySettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @Binding var availableDisplays: [NotchDisplayOption]
    
    var body: some View {
        SettingsPageScrollView {
            displayCard
        }
        .onAppear(perform: refreshAvailableDisplays)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refreshAvailableDisplays()
        }
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
                SpecificDisplayPicker (
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
